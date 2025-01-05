open Lwt.Infix

module User = struct
  type t = {
    id : string;
    username : string;
    password_hash : string;
    created_at : Ptime.t;
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
    (unit ->. unit)
    @@ {eos|
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL
      )
    |eos}

  let insert_user =
    (user ->. unit)
    @@ {eos|
      INSERT INTO users (id, username, password_hash, created_at)
      VALUES (?, ?, ?, ?)
    |eos}

  let find_user_by_id =
    (string ->? user)
    @@ "SELECT id, username, password_hash, created_at FROM users WHERE id = ?"

  let find_user_by_username =
    (string ->? user)
    @@ "SELECT id, username, password_hash, created_at FROM users WHERE username = ?"

    let get_user_count =
      (unit ->? int)
      @@ {eos|
        SELECT COALESCE(COUNT(*), 0) FROM users
      |eos} 
end


let create_table (module Db : Caqti_lwt.CONNECTION) = Db.exec Q.create_table ()

let insert_user (module Db : Caqti_lwt.CONNECTION) user =
  Db.exec Q.insert_user user

let find_user_by_id (module Db : Caqti_lwt.CONNECTION) id =
  Db.find_opt Q.find_user_by_id id

let find_user_by_username (module Db : Caqti_lwt.CONNECTION) username =
  Db.find_opt Q.find_user_by_username username

let get_user_count (module Db : Caqti_lwt.CONNECTION) =
  Db.find_opt Q.get_user_count () >|= function
  | Ok (Some count) -> count
  | Ok None -> 0
  | Error _ -> 0
  
(* Helper functions *)
let hash_password password =
  Digestif.SHA256.digest_string password |> Digestif.SHA256.to_hex

let create ~username ~password =
  let id =
    Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string
  in
  let password_hash = hash_password password in
  { id; username; password_hash; created_at = Ptime_clock.now () }

let verify_password t password =
  String.equal t.password_hash (hash_password password)

(* Types for authentication results *)
type auth_error = UserNotFound | InvalidPassword | UsernameTaken

let authenticate (module Db : Caqti_lwt.CONNECTION) ~username ~password =
  let%lwt user_result = find_user_by_username (module Db) username in
  match user_result with
  | Ok (Some user) ->
      if verify_password user password then
        Lwt.return_ok user
      else
        Lwt.return (Error InvalidPassword)
  | Ok None -> Lwt.return (Error UserNotFound)
  | Error _ -> Lwt.return (Error UserNotFound)

let register (module Db : Caqti_lwt.CONNECTION) ~username ~password =
  let%lwt existing_result = find_user_by_username (module Db) username in
  match existing_result with
  | Ok (Some _) -> Lwt.return (Error UsernameTaken)
  | Ok None -> (
      let user = create ~username ~password in
      match%lwt insert_user (module Db) user with
      | Ok () -> Lwt.return (Ok user)
      | Error _ -> Lwt.return (Error UsernameTaken))
  | Error _ -> Lwt.return (Error UsernameTaken)

let username_exists (module Db : Caqti_lwt.CONNECTION) username =
  find_user_by_username (module Db) username >|= function
  | Ok (Some _) -> true
  | Ok None -> false
  | Error _ -> false

(* Safe user view (without password hash) *)
type user_view = { id : string; username : string; created_at : Ptime.t }

let to_view (user : t) : user_view =
  { id = user.id; username = user.username; created_at = user.created_at }

let find_user_by_id_view (module Db : Caqti_lwt.CONNECTION) id =
  let%lwt result = find_user_by_id (module Db) id in
    match result with
    | Ok (Some user) -> Lwt.return (Ok (Some (to_view user)))
    | Ok None -> Lwt.return (Ok None)
    | Error err -> Lwt.return (Error err)
  