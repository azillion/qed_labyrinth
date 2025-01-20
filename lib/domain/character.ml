open Lwt.Syntax
open Infra

type t = {
  id : string;
  user_id : string;
  name : string;
  created_at : Ptime.t;
  deleted_at : Ptime.t option;
}

type error =
  | CharacterNotFound
  | UserNotFound
  | NameTaken
  | DatabaseError of string
[@@deriving yojson]

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let character_type =
    let encode { id; user_id; name; created_at; deleted_at } =
      Ok (id, user_id, name, created_at, deleted_at)
    in
    let decode (id, user_id, name, created_at, deleted_at) =
      Ok { id; user_id; name; created_at; deleted_at }
    in
    let rep = t5 string string string ptime (option ptime) in
    custom ~encode ~decode rep

  let insert =
    (character_type ->. unit)
      {| INSERT INTO characters (id, user_id, name, created_at, deleted_at)
         VALUES (?, ?, ?, ?, ?) |}

  let find_by_id =
    (string ->? character_type)
      "SELECT * FROM characters WHERE id = ? AND deleted_at IS NULL"

  let find_by_user_and_name =
    (t2 string string ->? character_type)
      "SELECT * FROM characters WHERE user_id = ? AND name = ? AND deleted_at IS NULL"

  let find_all_by_user =
    (string ->* character_type)
      "SELECT * FROM characters WHERE user_id = ? AND deleted_at IS NULL ORDER BY created_at"

  let soft_delete =
    (t2 ptime string ->. unit)
      {| UPDATE characters 
         SET deleted_at = ?
         WHERE id = ? AND deleted_at IS NULL |}
end

let create ~user_id ~name =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    (* First check if user exists *)
    let* user_exists = Db.find_opt User.Q.find_by_id user_id in
    match user_exists with
    | Error e -> Lwt_result.fail e
    | Ok None -> Lwt_result.return (`UserNotFound : [ `UserNotFound | `NameTaken | `Success of t ])
    | Ok (Some _) ->
        (* Then check for name uniqueness *)
        let* existing = Db.find_opt Q.find_by_user_and_name (user_id, name) in
        match existing with
        | Error e -> Lwt_result.fail e
        | Ok (Some _) -> Lwt_result.return (`NameTaken)
        | Ok None ->
            let character = {
              id = Uuidm.to_string (uuid ());
              user_id;
              name;
              created_at = Ptime_clock.now ();
              deleted_at = None;
            } in
            match%lwt Db.exec Q.insert character with
            | Error e -> Lwt_result.fail e
            | Ok () -> Lwt_result.return (`Success character)
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok (`Success character) -> Lwt.return_ok character
  | Ok `UserNotFound -> Lwt.return_error UserNotFound
  | Ok `NameTaken -> Lwt.return_error NameTaken
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let find_by_id id =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* result = Db.find_opt Q.find_by_id id in
    match result with
    | Error e -> Lwt_result.fail e
    | Ok result -> Lwt_result.return result
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok (Some character) -> Lwt.return_ok character
  | Ok None -> Lwt.return_error CharacterNotFound

let find_by_user_and_name ~user_id ~name =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* result = Db.find_opt Q.find_by_user_and_name (user_id, name) in
    match result with
    | Error e -> Lwt_result.fail e
    | Ok result -> Lwt_result.return result
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok (Some character) -> Lwt.return_ok character
  | Ok None -> Lwt.return_error CharacterNotFound

let find_all_by_user ~user_id =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* result = Db.collect_list Q.find_all_by_user user_id in
    match result with
    | Error e -> Lwt_result.fail e
    | Ok characters -> Lwt_result.return characters
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok characters -> Lwt.return_ok characters

let soft_delete ~character_id =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let now = Ptime_clock.now () in
    match%lwt Db.exec Q.soft_delete (now, character_id) with
    | Ok () -> Lwt_result.return ()
    | Error e -> Lwt_result.fail e
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok () -> Lwt.return_ok ()
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))