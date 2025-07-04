open Base
open Infra

module CoreStats = struct
  type t = {
    character_id : string;
    might : int;
    finesse : int;
    wits : int;
    grit : int;
    presence : int;
  }
end

type t = {
  id : string;
  user_id : string;
  name : string;
  core_stats : CoreStats.t;
}

let uuid = Uuidm.v4_gen (Stdlib.Random.State.make_self_init ())

module Q = struct
  let core_stats_type =
    Caqti_type.Std.custom
      ~encode:(fun { CoreStats.character_id; might; finesse; wits; grit; presence } ->
        Ok (character_id, might, finesse, wits, grit, presence))
      ~decode:(fun (character_id, might, finesse, wits, grit, presence) ->
        Ok { CoreStats.character_id; might; finesse; wits; grit; presence })
      Caqti_type.Std.(t6 string int int int int int)

  let insert_character =
    Caqti_request.Infix.(Caqti_type.Std.(t3 string string string) ->. Caqti_type.unit)
      "INSERT INTO characters (id, user_id, name) VALUES (?, ?, ?)"

  let insert_core_stats =
    Caqti_request.Infix.(core_stats_type ->. Caqti_type.unit)
      "INSERT INTO character_core_stats (character_id, might, finesse, wits, grit, presence) VALUES (?, ?, ?, ?, ?, ?)"

  let find_character_by_id =
    Caqti_request.Infix.(Caqti_type.Std.string ->? Caqti_type.Std.(t3 string string string))
      "SELECT id, user_id, name FROM characters WHERE id = ?"

  let find_core_stats_by_character_id =
    Caqti_request.Infix.(Caqti_type.Std.string ->? core_stats_type)
      "SELECT character_id, might, finesse, wits, grit, presence FROM character_core_stats WHERE character_id = ?"
end

let create ~user_id ~name ~might ~finesse ~wits ~grit ~presence =
  let character_id = Uuidm.to_string (uuid ()) in
  let character = (character_id, user_id, name) in
  let core_stats = { CoreStats.character_id; might; finesse; wits; grit; presence } in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let%lwt result1 = Db.exec Q.insert_character character in
    match result1 with
    | Error e -> Lwt_result.fail e
    | Ok () ->
        let%lwt result2 = Db.exec Q.insert_core_stats core_stats in
        match result2 with
        | Error e -> Lwt_result.fail e
        | Ok () -> Lwt_result.return { id = character_id; user_id; name; core_stats }
  in
  match%lwt Database.Pool.use db_operation with
  | Ok result -> Lwt_result.return result
  | Error err -> Lwt_result.fail (Qed_error.DatabaseError (Error.to_string_hum err))

let find_by_id character_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let%lwt result1 = Db.find_opt Q.find_character_by_id character_id in
    match result1 with
    | Error e -> Lwt_result.fail e
    | Ok (Some (id, user_id, name)) ->
        let%lwt result2 = Db.find_opt Q.find_core_stats_by_character_id character_id in
        (match result2 with
         | Error e -> Lwt_result.fail e
         | Ok (Some core_stats) ->
           Lwt_result.return (Some { id; user_id; name; core_stats })
         | Ok None ->
           Lwt_result.return None)
    | Ok None ->
        Lwt_result.return None
  in
  match%lwt Database.Pool.use db_operation with
  | Ok result -> Lwt_result.return result
  | Error err -> Lwt_result.fail (Qed_error.DatabaseError (Error.to_string_hum err))

let find_all_by_user ~user_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let query = Caqti_request.Infix.(Caqti_type.Std.string ->* Caqti_type.Std.(t3 string string string))
      "SELECT id, user_id, name FROM characters WHERE user_id = ?" in
    let%lwt rows_result = Db.collect_list query user_id in
    match rows_result with
    | Error e -> Lwt_result.fail e
    | Ok rows ->
        let default_stats id = { CoreStats.character_id = id; might = 0; finesse = 0; wits = 0; grit = 0; presence = 0 } in
        let characters = List.map rows ~f:(fun (id, uid, name) -> { id; user_id = uid; name; core_stats = default_stats id }) in
        Lwt_result.return characters
  in
  match%lwt Database.Pool.use db_operation with
  | Ok result -> Lwt_result.return result
  | Error err -> Lwt_result.fail (Qed_error.DatabaseError (Error.to_string_hum err))