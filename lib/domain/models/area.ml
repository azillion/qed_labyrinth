open Lwt.Syntax
open Infra

type t = {
  id : string;
  name : string;
  description : string;
  x : int;
  y : int;
  z : int;
}

type error =
  | AreaNotFound
  | DatabaseError of string
[@@deriving yojson]

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

type direction = North | South | East | West | Up | Down
[@@deriving yojson]

let direction_to_string = function
  | North -> "north"
  | South -> "south"
  | East -> "east"
  | West -> "west"
  | Up -> "up"
  | Down -> "down"

let string_to_direction = function
  | "north" -> Some North
  | "south" -> Some South
  | "east" -> Some East
  | "west" -> Some West
  | "up" -> Some Up
  | "down" -> Some Down
  | _ -> None

type exit = {
  from_area_id : string;
  to_area_id : string;
  direction : direction;
  description : string option;
  hidden : bool;
  locked : bool;
}

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let area_type =
    let encode { id; name; description; x; y; z } =
      Ok (id, name, description, x, y, z)
    in
    let decode (id, name, description, x, y, z) =
      Ok { id; name; description; x; y; z }
    in
    let rep = t6 string string string int int int in
    custom ~encode ~decode rep

  let insert =
    (area_type ->. unit)
      {| INSERT INTO areas (id, name, description, x, y, z)
         VALUES (?, ?, ?, ?, ?, ?) |}

  let find_by_id =
    (string ->? area_type)
      "SELECT id, name, description, x, y, z FROM areas WHERE id = ?"

  let exit_type =
    let encode { from_area_id; to_area_id; direction; description; hidden; locked } =
      Ok (from_area_id, to_area_id, direction_to_string direction, description, hidden, locked)
    in
    let decode (from_area_id, to_area_id, direction, description, hidden, locked) =
      match string_to_direction direction with
      | Some dir -> Ok { from_area_id; to_area_id; direction = dir; description; hidden; locked }
      | None -> Error "Invalid direction"
    in
    let rep = t6 string string string (option string) bool bool in
    custom ~encode ~decode rep

  let insert_exit =
    (exit_type ->. unit)
      {| INSERT INTO exits 
         (from_area_id, to_area_id, direction, description, hidden, locked)
         VALUES (?, ?, ?, ?, ?, ?) |}

  let find_exits =
    (string ->* exit_type)
      {| SELECT from_area_id, to_area_id, direction, description, hidden, locked
         FROM exits
         WHERE from_area_id = ? |}

  let direction_type =
    let encode d = Ok (direction_to_string d) in
    let decode s = 
      match string_to_direction s with
      | Some d -> Ok d
      | None -> Error "Invalid direction"
    in
    custom ~encode ~decode string

  let find_exit_by_direction =
    (t2 string direction_type ->? option exit_type)
      {| SELECT from_area_id, to_area_id, direction, description, hidden, locked
         FROM exits
         WHERE from_area_id = ? AND direction = ? |}
end

let create ~name ~description ~x ~y ~z =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let area = {
      id = Uuidm.to_string (uuid ());
      name;
      description;
      x;
      y;
      z;
    } in
    match%lwt Db.exec Q.insert area with
    | Error e -> Lwt_result.fail e
    | Ok () -> Lwt_result.return area
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok area -> Lwt.return_ok area
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
  | Ok (Some area) -> Lwt.return_ok area
  | Ok None -> Lwt.return_error AreaNotFound

let get_exits area =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* result = Db.collect_list Q.find_exits area.id in
    match result with
    | Error e -> Lwt_result.fail e
    | Ok exits -> Lwt_result.return exits
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok exits -> Lwt.return_ok exits

let create_exit ~from_area_id ~to_area_id ~direction ~description ~hidden ~locked =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    (* First verify both areas exist *)
    let* from_area = Db.find_opt Q.find_by_id from_area_id in
    let* to_area = Db.find_opt Q.find_by_id to_area_id in
    match (from_area, to_area) with
    | (Error e, _) | (_, Error e) -> Lwt_result.fail e

    | (Ok None, _) | (_, Ok None) -> Lwt_result.return (`AreaNotFound)
    | (Ok (Some _), Ok (Some _)) ->
        let exit = {
          from_area_id;
          to_area_id;
          direction;
          description = Option.map ~f:(fun d -> d) description;
          hidden;
          locked;
        } in
        match%lwt Db.exec Q.insert_exit exit with
        | Error e -> Lwt_result.fail e
        | Ok () -> Lwt_result.return (`Success exit)
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok (`Success exit) -> Lwt.return_ok exit
  | Ok `AreaNotFound -> Lwt.return_error AreaNotFound
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let find_exits ~area_id =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* result = Db.collect_list Q.find_exits area_id in
    match result with
    | Error e -> Lwt_result.fail e
    | Ok exits -> Lwt_result.return exits
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok exits -> Lwt.return_ok exits

let direction_equal a b =
  match a, b with
  | North, North -> true
  | South, South -> true
  | East, East -> true
  | West, West -> true
  | Up, Up -> true
  | Down, Down -> true
  | _, _ -> false
