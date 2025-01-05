module Character = struct
  type t = {
    id : string;
    user_id : string;
    name : string;
    location_id : string;
    created_at : Ptime.t;
  }
end

include Character

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let character =
    let open Character in
    let intro id user_id name location_id created_at =
      { id; user_id; name; location_id; created_at }
    in
    product intro
    @@ proj string (fun c -> c.id)
    @@ proj string (fun c -> c.user_id)
    @@ proj string (fun c -> c.name)
    @@ proj string (fun c -> c.location_id)
    @@ proj ptime (fun c -> c.created_at)
    @@ proj_end

  let create_table =
    unit ->. unit @@
    {eos|
      CREATE TABLE IF NOT EXISTS characters (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        location_id TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL
      )
    |eos}

  let insert_character =
    character ->. unit @@
    {eos|
      INSERT INTO characters (id, user_id, name, location_id, created_at)
      VALUES (?, ?, ?, ?, ?)
    |eos}

  let find_character_by_id =
    string ->? character @@
    "SELECT id, user_id, name, location_id, created_at FROM characters WHERE id = ?"

  let get_all_characters =
    unit ->* character @@
    "SELECT id, user_id, name, location_id, created_at FROM characters"
end

let create_table (module Db : Caqti_lwt.CONNECTION) =
  Db.exec Q.create_table ()

let insert_character (module Db : Caqti_lwt.CONNECTION) character =
  Db.exec Q.insert_character character

let find_character_by_id (module Db : Caqti_lwt.CONNECTION) id =
  Db.find_opt Q.find_character_by_id id

let iter_all_characters (module Db : Caqti_lwt.CONNECTION) f =
  Db.iter_s Q.get_all_characters f ()

let create ~user_id ~name ~location_id =
  let id = Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string in
  {
    id;
    user_id;
    name;
    location_id;
    created_at = Ptime_clock.now ();
  }
