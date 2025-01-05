module User = struct
  type t = {
    id: string;
    username: string;
    password_hash: string;
    created_at: Ptime.t;
  }
end
include User

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let user =
    let open User in
    let intro id username password_hash created_at =
      { id; username; password_hash; created_at }
    in
    product intro
    @@ proj string (fun u -> u.id)
    @@ proj string (fun u -> u.username)
    @@ proj string (fun u -> u.password_hash)
    @@ proj ptime (fun u -> u.created_at)
    @@ proj_end

  let create_table =
    unit ->. unit @@
    {eos|
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL
      )
    |eos}

  let insert_user =
    user ->. unit @@
    {eos|
      INSERT INTO users (id, username, password_hash, created_at)
      VALUES (?, ?, ?, ?)
    |eos}
    
  let find_user_by_id =
    string ->? user @@
    "SELECT id, username, password_hash, created_at FROM users WHERE id = ?"
    
  let find_user_by_username =
    string ->? user @@
    "SELECT id, username, password_hash, created_at FROM users WHERE username = ?"
end

let create_table (module Db : Caqti_lwt.CONNECTION) =
  Db.exec Q.create_table ()

let insert_user (module Db : Caqti_lwt.CONNECTION) user =
  Db.exec Q.insert_user user

let find_user_by_id (module Db : Caqti_lwt.CONNECTION) id =
  Db.find_opt Q.find_user_by_id id

let find_user_by_username (module Db : Caqti_lwt.CONNECTION) username =
  Db.find_opt Q.find_user_by_username username

(* Helper functions *)
let hash_password password =
  Digestif.SHA256.digest_string password |> Digestif.SHA256.to_hex

let create ~username ~password = 
  let id = Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string in
  let password_hash = hash_password password in
  {
    id;
    username;
    password_hash;
    created_at = Ptime_clock.now ();
  }

let verify_password t password =
  String.equal t.password_hash (hash_password password)
