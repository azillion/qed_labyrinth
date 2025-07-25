open Lwt.Syntax
open Infra
open Qed_error

type climate = {
  elevation: float;
  temperature: float;
  moisture: float;
} [@@deriving yojson]

type room_type = 
  | Cave 
  | Forest 
  | Grassland
  | Mountain 
  | Swamp 
  | Desert 
  | Tundra 
  | Lake 
  | Canyon 
  | Volcano 
  | Jungle [@@deriving yojson]

type t = {
  id : string;
  name : string;
  description : string;
  x : int;
  y : int;
  z : int;
  elevation : float option;
  temperature : float option;
  moisture : float option;
}

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

type direction = North | South | East | West | Up | Down [@@deriving yojson]

let opposite_direction = function
  | North -> South
  | South -> North
  | East -> West
  | West -> East
  | Up -> Down
  | Down -> Up

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
    let encode { id; name; description; x; y; z; 
                elevation; temperature; moisture } =
      Ok (id, name, description, x, y, z, 
          elevation, temperature, moisture)
    in
    let decode (id, name, description, x, y, z, 
               elevation, temperature, moisture) =
      Ok { id; name; description; x; y; z;
           elevation; temperature; moisture }
    in
    custom ~encode ~decode 
      (t9 string string string int int int 
          (option float) (option float) (option float))

  let insert =
    (area_type ->. unit)
      {| INSERT INTO areas 
         (id, name, description, x, y, z, 
          climate_elevation, climate_temperature, climate_moisture)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) |}

  let find_by_id =
    (string ->? area_type)
      {| SELECT id, name, description, x, y, z,
         climate_elevation, climate_temperature, climate_moisture
         FROM areas WHERE id = ? |}

  let exit_type =
    let encode
        { from_area_id; to_area_id; direction; description; hidden; locked } =
      Ok
        ( from_area_id,
          to_area_id,
          direction_to_string direction,
          description,
          hidden,
          locked )
    in
    let decode (from_area_id, to_area_id, direction, description, hidden, locked)
        =
      match string_to_direction direction with
      | Some dir ->
          Ok
            {
              from_area_id;
              to_area_id;
              direction = dir;
              description;
              hidden;
              locked;
            }
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

  let find_by_coordinates =
    (t3 int int int ->? area_type)
      {| SELECT id, name, description, x, y, z,
         climate_elevation, climate_temperature, climate_moisture
         FROM areas WHERE x = ? AND y = ? AND z = ? |}

  let delete_all_except_starting_area =
    (string ->. unit)
      {| DELETE FROM areas WHERE id <> ? |}
    
  let delete_all_exits =
    (unit ->. unit)
      {| DELETE FROM exits |}

  let find_all_nearby_areas =
    (t6 int int int int int int ->* area_type)
      {| SELECT *
         FROM areas WHERE x BETWEEN ? AND ? AND y BETWEEN ? AND ? AND z BETWEEN ? AND ? |}

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
  

         let find_all_areas =
          (unit ->* area_type) "SELECT * FROM areas"
        
        let find_all_exits = 
          (unit ->* exit_type) "SELECT * FROM exits"

  let update_area_name_and_description =
    (t3 string string string ->. unit)
      {| UPDATE areas SET name = ?, description = ? WHERE id = ? |}
end

let create ~name ~description ~x ~y ~z ?id ?elevation ?temperature ?moisture () =
  let open Base in
  let id = match id with
    | Some id -> id
    | None -> Uuidm.to_string (uuid ())
  in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let area = { 
      id;
      name; 
      description; 
      x; 
      y; 
      z; 
      elevation;
      temperature;
      moisture;
    } in
    match%lwt Db.exec Q.insert area with
    | Error e -> Lwt_result.fail e
    | Ok () -> Lwt_result.return area
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok area -> Lwt.return_ok area
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let create_with_climate ~name ~description ~x ~y ~z ~(climate : climate) () =
  create 
    ~name 
    ~description 
    ~x ~y ~z 
    ~elevation:climate.elevation
    ~temperature:climate.temperature
    ~moisture:climate.moisture
    ()

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
  match (a, b) with
  | North, North -> true
  | South, South -> true
  | East, East -> true
  | West, West -> true
  | Up, Up -> true
  | Down, Down -> true
  | _, _ -> false

  let find_by_coordinates ~x ~y ~z =
    let open Base in
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let* result = Db.find_opt Q.find_by_coordinates (x, y, z) in
      match result with
      | Error e -> Lwt_result.fail e
      | Ok result -> Lwt_result.return result
    in
    let* result = Database.Pool.use db_operation in
    match result with
    | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
    | Ok (Some area) -> Lwt.return_ok area
    | Ok None -> Lwt.return_error AreaNotFound

    let exists ~x ~y ~z =
      match%lwt find_by_coordinates ~x ~y ~z with
      | Ok _ -> Lwt.return_ok true
      | Error AreaNotFound -> Lwt.return_ok false
      | Error e -> Lwt.return_error e

let delete_all_except_starting_area starting_area_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    (* Delete all exits not connected to the starting area *)
    let* _ = Db.exec Q.delete_all_exits () in
    (* Delete all areas except the starting area *)
    let* _ = Db.exec Q.delete_all_except_starting_area starting_area_id in
    Lwt_result.return ()
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok () -> Lwt.return_ok ()
  | Error e -> Lwt.return_error (DatabaseError (Base.Error.to_string_hum e))


  let get_all_areas () =
    let open Base in
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let* result = Db.collect_list Q.find_all_areas () in
      match result with
      | Error e -> Lwt_result.fail e
      | Ok areas -> Lwt_result.return areas
    in
    let* result = Database.Pool.use db_operation in
    match result with
    | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
    | Ok areas -> Lwt.return_ok areas

let get_all_exits () =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* result = Db.collect_list Q.find_all_exits () in
    match result with
    | Error e -> Lwt_result.fail e
    | Ok exits -> Lwt_result.return exits
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok exits -> Lwt.return_ok exits

let get_all_nearby_areas location_id ~max_distance =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* area_result = Db.find_opt Q.find_by_id location_id in
    match area_result with
    | Error e -> Lwt_result.fail e
    | Ok result -> 
        match result with
        | None -> Lwt_result.return None
        | Some area -> 
            let x_min, x_max = area.x - max_distance, area.x + max_distance in
            let y_min, y_max = area.y - max_distance, area.y + max_distance in 
            let z_min, z_max = area.z - max_distance, area.z + max_distance in
            let* result = Db.collect_list Q.find_all_nearby_areas (x_min, x_max, y_min, y_max, z_min, z_max) in
            match result with
            | Error e -> Lwt_result.fail e
            | Ok areas -> Lwt_result.return (Some areas)
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok None -> Lwt.return_error AreaNotFound
  | Ok (Some areas) -> Lwt.return_ok areas

let update_area_name_and_description ~location_id ~name ~description =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* _ = Db.exec Q.update_area_name_and_description (name, description, location_id) in
    Lwt_result.return ()
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok () -> Lwt.return_ok ()
  | Error e -> 
    Stdio.print_endline (Printf.sprintf "Error updating area: %s" (Error.to_string_hum e));
    Lwt.return_error (DatabaseError (Error.to_string_hum e))

