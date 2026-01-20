open Base
open Infra
open Qed_error

type direction = Components.ExitComponent.direction

type t = {
  id: string;
  from_area_id: string;
  to_area_id: string;
  direction: direction;
}

let uuid = Uuidm.v4_gen (Stdlib.Random.State.make_self_init ())

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let direction_type =
    let encode d = Ok (Components.ExitComponent.direction_to_string d) in
    let decode s =
      match Components.ExitComponent.string_to_direction s with
      | Some d -> Ok d
      | None -> Error "Invalid direction string"
    in
    custom ~encode ~decode string

  let exit_type =
    let encode { id; from_area_id; to_area_id; direction } =
      Ok (id, from_area_id, to_area_id, direction)
    in
    let decode (id, from_area_id, to_area_id, direction) =
      Ok { id; from_area_id; to_area_id; direction }
    in
    custom ~encode ~decode (t4 string string string direction_type)

  let insert =
    (exit_type ->. unit)
      {| INSERT INTO exits (id, from_area_id, to_area_id, direction)
         VALUES (?, ?, ?, ?) |}

  let find_by_area_and_direction =
    (t2 string direction_type ->? exit_type)
      "SELECT * FROM exits WHERE from_area_id = ? AND direction = ?"
      
  let find_by_area =
    (string ->* exit_type)
      "SELECT * FROM exits WHERE from_area_id = ?"
end

let create ~from_area_id ~to_area_id ~direction =
  let forward_exit =
    { id = Uuidm.to_string (uuid ()); from_area_id; to_area_id; direction }
  in
  let reciprocal_exit =
    {
      id = Uuidm.to_string (uuid ());
      from_area_id = to_area_id;
      to_area_id = from_area_id;
      direction = Components.ExitComponent.opposite_direction direction;
    }
  in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let open Lwt_result.Syntax in
    let* () = Db.start () in
    match%lwt Db.exec Q.insert forward_exit with
    | Error e -> 
        let%lwt _ = Db.rollback () in
        Lwt_result.fail e
    | Ok () ->
        match%lwt Db.exec Q.insert reciprocal_exit with
        | Error e ->
            let%lwt _ = Db.rollback () in
            Lwt_result.fail e
        | Ok () ->
            let* () = Db.commit () in
            Lwt_result.return forward_exit
  in
  match%lwt Database.Pool.use db_operation with
  | Ok record -> Lwt.return_ok record
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let find_by_area_and_direction ~area_id ~direction =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    Db.find_opt Q.find_by_area_and_direction (area_id, direction)
  in
  match%lwt Database.Pool.use db_operation with
  | Ok (Some exit_record) -> Lwt.return_ok (Some exit_record)
  | Ok None -> Lwt.return_ok None
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let find_by_area ~area_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    Db.collect_list Q.find_by_area area_id
  in
  match%lwt Database.Pool.use db_operation with
  | Ok exits -> Lwt.return_ok exits
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))