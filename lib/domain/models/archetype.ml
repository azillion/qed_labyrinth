open Base
open Infra
open Qed_error

type t = {
  id: string;
  version: int;
  params: Yojson.Safe.t;
  prompts: Yojson.Safe.t;
}

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let archetype_type =
    let encode { id; version; params; prompts } =
      Ok (id, version, Yojson.Safe.to_string params, Yojson.Safe.to_string prompts)
    in
    let decode (id, version, params_str, prompts_str) =
      try
        let params = Yojson.Safe.from_string params_str in
        let prompts = Yojson.Safe.from_string prompts_str in
        Ok { id; version; params; prompts }
      with Yojson.Json_error msg -> Error (Printf.sprintf "JSON parsing error: %s" msg)
    in
    custom ~encode ~decode (t4 string int string string)

  let find_by_id =
    (string ->? archetype_type)
      "SELECT id, version, params, prompts FROM archetypes WHERE id = ?"
end

let find_by_id id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    Db.find_opt Q.find_by_id id
  in
  match%lwt Database.Pool.use db_operation with
  | Ok result -> Lwt.return_ok result
  | Error err -> Lwt.return_error (DatabaseError (Error.to_string_hum err))