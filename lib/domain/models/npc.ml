open Base
open Infra
open Qed_error

type t = {
  id: string;
  archetype_id: string;
  name: string;
  description: string;
}

let uuid = Uuidm.v4_gen (Stdlib.Random.State.make_self_init ())

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let npc_type =
    let encode { id; archetype_id; name; description } =
      Ok (id, archetype_id, name, description)
    in
    let decode (id, archetype_id, name, description) =
      Ok { id; archetype_id; name; description }
    in
    custom ~encode ~decode (t4 string string string string)

  let insert_entity =
    (string ->. unit)
      "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING"

  let insert_npc =
    (npc_type ->. unit)
      "INSERT INTO npcs (id, archetype_id, name, description) VALUES (?, ?, ?, ?)"
end

let create ~archetype_id ~name ~description =
  let entity_id = Uuidm.to_string (uuid ()) in
  let npc_record = { id = entity_id; archetype_id; name; description } in

  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let open Lwt_result.Syntax in
    (* Transaction to ensure both entity and npc are created *)
    let* () = Db.start () in
    let* () =
      match%lwt Db.exec Q.insert_entity entity_id with
      | Ok () -> Lwt_result.return ()
      | Error e ->
          let* _ = Db.rollback () in
          Lwt_result.fail e
    in
    match%lwt Db.exec Q.insert_npc npc_record with
    | Ok () ->
        let* () = Db.commit () in
        Lwt_result.return npc_record
    | Error e ->
        let* _ = Db.rollback () in
        Lwt_result.fail e
  in

  match%lwt Database.Pool.use db_operation with
  | Ok record -> Lwt.return_ok record
  | Error err -> Lwt.return_error (DatabaseError (Error.to_string_hum err))


