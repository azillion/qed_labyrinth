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
    let open Lwt_result.Syntax in
    let* () = Db.start () in
    match%lwt Db.exec Q.insert_character character with
    | Error e -> 
        let%lwt _ = Db.rollback () in
        Lwt_result.fail e
    | Ok () ->
        match%lwt Db.exec Q.insert_core_stats core_stats with
        | Error e ->
            let%lwt _ = Db.rollback () in
            Lwt_result.fail e
        | Ok () ->
            let* () = Db.commit () in
            Lwt_result.return { id = character_id; user_id; name; core_stats }
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
    let query =
      Caqti_request.Infix.(Caqti_type.Std.string ->*
        Caqti_type.Std.(t8 string string string int int int int int))
        {| SELECT c.id, c.user_id, c.name, s.might, s.finesse, s.wits, s.grit, s.presence
           FROM characters c
           JOIN character_core_stats s ON c.id = s.character_id
           WHERE c.user_id = ? |}
    in
    let%lwt result = Db.collect_list query user_id in
    match result with
    | Ok rows ->
        let characters = List.map rows ~f:(fun (id, user_id, name, might, finesse, wits, grit, presence) ->
          let core_stats = { CoreStats.character_id = id; might; finesse; wits; grit; presence } in
          { id; user_id; name; core_stats })
        in
        Lwt_result.return characters
    | Error e ->
        Stdio.eprintf "[DB_ERROR] find_all_by_user: %s\n" (Caqti_error.show e);
        Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok characters -> Lwt.return_ok characters
  | Error e -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum e))

let find_many_by_ids character_ids =
  if List.is_empty character_ids then Lwt.return_ok []
  else
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let open Caqti_type.Std in
      let query =
        Caqti_request.Infix.(string ->*
          (t8 string string string int int int int int))
          {| SELECT c.id, c.user_id, c.name, s.might, s.finesse, s.wits, s.grit, s.presence
             FROM characters c
             JOIN character_core_stats s ON c.id = s.character_id
             WHERE c.id = ANY (?::text[]) |}
      in
      let pg_array = "{" ^ (String.concat ~sep:"," character_ids) ^ "}" in
      let%lwt result = Db.collect_list query pg_array in
      match result with
      | Ok rows ->
          let characters = List.map rows ~f:(fun (id, user_id, name, might, finesse, wits, grit, presence) ->
            let core_stats = { CoreStats.character_id = id; might; finesse; wits; grit; presence } in
            { id; user_id; name; core_stats })
          in
          Lwt_result.return characters
      | Error e -> Lwt_result.fail e
    in
    match%lwt Database.Pool.use db_operation with
    | Ok characters -> Lwt.return_ok characters
    | Error e -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum e))