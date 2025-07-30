open Base
open Infra

type t = {
  id : string;
  user_id : string;
  name : string;
  proficiency_level : int;
  current_xp : int;
  saga_tier : int;
  current_ip : int;
}

let uuid = Uuidm.v4_gen (Stdlib.Random.State.make_self_init ())

module Q = struct
  let insert_character =
    Caqti_request.Infix.(Caqti_type.Std.(t7 string string string int int int int) ->. Caqti_type.unit)
      "INSERT INTO characters (id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip) VALUES (?, ?, ?, ?, ?, ?, ?)"

  let find_character_by_id =
    Caqti_request.Infix.(Caqti_type.Std.string ->? Caqti_type.Std.(t7 string string string int int int int))
      "SELECT id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip FROM characters WHERE id = ?"

  (* update_progression query *)
  let update_progression =
    Caqti_request.Infix.(Caqti_type.Std.(t3 int int string) ->. Caqti_type.unit)
      "UPDATE characters SET current_xp = current_xp + ?, current_ip = current_ip + ? WHERE id = ?"
end

let create ~user_id ~name =
  let character_id = Uuidm.to_string (uuid ()) in
  let proficiency_level = 1 in
  let current_xp = 0 in
  let saga_tier = 1 in
  let current_ip = 0 in
  let character_tuple =
    (character_id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip)
  in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.exec Q.insert_character character_tuple with
    | Ok () ->
        Lwt_result.return
          { id = character_id;
            user_id;
            name;
            proficiency_level;
            current_xp;
            saga_tier;
            current_ip }
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok res -> Lwt.return_ok res
  | Error err ->
      let msg = Error.to_string_hum err in
      let mapped = if String.is_substring msg ~substring:"characters_name_key" then Qed_error.NameTaken else Qed_error.DatabaseError msg in
      Lwt.return_error mapped

let find_by_id character_id ?conn () =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.find_opt Q.find_character_by_id character_id with
    | Ok (Some (id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip)) ->
        Lwt_result.return (Some { id; user_id; name; proficiency_level; current_xp; saga_tier; current_ip })
    | Ok None -> Lwt_result.return None
    | Error e -> Lwt_result.fail e
  in
  (match conn with
  | Some conn_module -> (
      match%lwt db_operation conn_module with
      | Ok res -> Lwt.return_ok res
      | Error err -> Lwt.return_error (Qed_error.DatabaseError (Caqti_error.show err)))
  | None -> (
      match%lwt Database.Pool.use db_operation with
      | Ok res -> Lwt.return_ok res
      | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))))

let find_all_by_user ~user_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let query =
      Caqti_request.Infix.(Caqti_type.Std.string ->*
        Caqti_type.Std.(t7 string string string int int int int))
        "SELECT id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip FROM characters WHERE user_id = ?"
    in
    match%lwt Db.collect_list query user_id with
    | Ok rows ->
        let characters =
          List.map rows ~f:(fun (id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip) ->
              { id; user_id; name; proficiency_level; current_xp; saga_tier; current_ip })
        in
        Lwt_result.return characters
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok chars -> Lwt.return_ok chars
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))

let find_many_by_ids character_ids =
  if List.is_empty character_ids then Lwt.return_ok []
  else
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let open Caqti_type.Std in
      let query =
        Caqti_request.Infix.(string ->*
          (t7 string string string int int int int))
          "SELECT id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip FROM characters WHERE id = ANY (?::text[])"
      in
      let pg_array = "{" ^ (String.concat ~sep:"," character_ids) ^ "}" in
      match%lwt Db.collect_list query pg_array with
      | Ok rows ->
          let characters = List.map rows ~f:(fun (id, user_id, name, proficiency_level, current_xp, saga_tier, current_ip) ->
            { id; user_id; name; proficiency_level; current_xp; saga_tier; current_ip })
          in
          Lwt_result.return characters
      | Error e -> Lwt_result.fail e
    in
    match%lwt Database.Pool.use db_operation with
    | Ok chars -> Lwt.return_ok chars
    | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))

let update_progression ~character_id ~xp_to_add ~ip_to_add =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.exec Q.update_progression (xp_to_add, ip_to_add, character_id) with
    | Ok () -> Lwt_result.return ()
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok () -> Lwt.return_ok ()
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))