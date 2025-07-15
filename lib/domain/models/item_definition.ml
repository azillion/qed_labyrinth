open Base
open Infra
open Qed_error

type item_type = Weapon | Armor | Consumable | Misc
let item_type_to_string = function
  | Weapon -> "WEAPON" | Armor -> "ARMOR" | Consumable -> "CONSUMABLE" | Misc -> "MISC"
let item_type_of_string = function
  | "WEAPON" -> Ok Weapon | "ARMOR" -> Ok Armor | "CONSUMABLE" -> Ok Consumable | "MISC" -> Ok Misc
  | _ -> Error "Invalid item_type"

type slot = MainHand | OffHand | Head | Chest | Legs | Feet | None
let slot_to_string = function
  | MainHand -> "MAIN_HAND" | OffHand -> "OFF_HAND" | Head -> "HEAD" | Chest -> "CHEST"
  | Legs -> "LEGS" | Feet -> "FEET" | None -> "NONE"
let slot_of_string = function
  | "MAIN_HAND" -> Ok MainHand | "OFF_HAND" -> Ok OffHand | "HEAD" -> Ok Head
  | "CHEST" -> Ok Chest | "LEGS" -> Ok Legs | "FEET" -> Ok Feet | "NONE" -> Ok None
  | _ -> Error "Invalid slot"

type t = {
  id : string;
  name : string;
  description : string;
  item_type : item_type;
  slot : slot;
  weight : float;
  is_stackable : bool;
  properties : Yojson.Safe.t option;
}

let uuid = Uuidm.v4_gen (Stdlib.Random.State.make_self_init ())

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let item_definition_type =
    let encode { id; name; description; item_type; slot; weight; is_stackable; properties } =
      let props_str = Option.map properties ~f:Yojson.Safe.to_string in
      Ok (id, name, description, item_type_to_string item_type, slot_to_string slot, weight, is_stackable, props_str)
    in
    let decode (id, name, description, item_type_str, slot_str, weight, is_stackable, properties_str) =
      match item_type_of_string item_type_str, slot_of_string slot_str with
      | Ok item_type, Ok slot ->
        let properties = Option.map properties_str ~f:Yojson.Safe.from_string in
        Ok { id; name; description; item_type; slot; weight; is_stackable; properties }
      | Error e, _ | _, Error e -> Error e
    in
    custom ~encode ~decode (t8 string string string string string float bool (option string))

  let insert =
    (item_definition_type ->. unit)
      "INSERT INTO item_definitions (id, name, description, item_type, slot, weight, is_stackable, properties) VALUES (?, ?, ?, ?, ?, ?, ?, ?::jsonb)"

  let find_by_id =
    (string ->? item_definition_type)
      "SELECT id, name, description, item_type, slot, weight, is_stackable, properties FROM item_definitions WHERE id = ?"
end

let create ~name ~description ~item_type ?(slot=None) ?(weight=0.0) ?(is_stackable=false) ?properties () =
  let item_def = {
    id = Uuidm.to_string (uuid ());
    name; description; item_type; slot; weight; is_stackable; properties
  } in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.exec Q.insert item_def with
    | Ok () -> Lwt_result.return item_def
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok result -> Lwt.return_ok result
  | Error err -> Lwt.return_error (DatabaseError (Error.to_string_hum err))

let find_by_id id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    Db.find_opt Q.find_by_id id
  in
  match%lwt Database.Pool.use db_operation with
  | Ok result -> Lwt.return_ok result
  | Error err -> Lwt.return_error (DatabaseError (Error.to_string_hum err)) 

(* Bulk lookup names by ids using a single SQL query *)
let find_names_by_ids ids =
  match ids with
  | [] -> Lwt.return_ok []
  | _ ->
    let open Caqti_type.Std in
    let query =
      Caqti_request.Infix.((string) ->* (t2 string string))
        "SELECT id, name FROM item_definitions WHERE id = ANY (?::text[])"
    in
    let pg_array = "{" ^ (String.concat ~sep:"," ids) ^ "}" in
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      Db.collect_list query pg_array
    in
    match%lwt Database.Pool.use db_operation with
    | Ok pairs ->
        let pairs_list = List.map pairs ~f:(fun (id, name) -> (id, name)) in
        Lwt.return_ok pairs_list
    | Error err -> Lwt.return_error (DatabaseError (Error.to_string_hum err)) 