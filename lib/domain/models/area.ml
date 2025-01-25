open Lwt.Syntax
open Infra

type climate = {
  elevation: float;
  temperature: float;
  moisture: float;
} [@@deriving yojson]

type room_type = 
  | Cave 
  | Forest 
  | Mountain 
  | Swamp 
  | Desert 
  | Tundra 
  | Lake 
  | Canyon [@@deriving yojson]

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

type error = AreaNotFound | DatabaseError of string [@@deriving yojson]

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

type direction = North | South | East | West | Up | Down [@@deriving yojson]

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

let create ~name ~description ~x ~y ~z ?elevation ?temperature ?moisture () =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let area = { 
      id = Uuidm.to_string (uuid ()); 
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

let get_climate t = 
  match t.elevation, t.temperature, t.moisture with
  | Some e, Some t, Some m ->
      Some { elevation = e; temperature = t; moisture = m }
  | _ -> None

let compute_room_type ({ elevation; temperature; moisture } : climate) =
  if elevation < -0.5 then Cave
  else if elevation > 0.6 then Mountain
  else if temperature < 0.2 then Tundra
  else if temperature > 0.7 && moisture < 0.2 then Desert
  else if moisture > 0.7 then
    if temperature > 0.6 then Swamp else Lake
  else if elevation > 0.3 then
    if moisture > 0.4 then Forest else Canyon
  else Forest

let get_room_type t = 
  match get_climate t with
  | Some climate -> Some (compute_room_type climate)
  | None -> None

let get_climate_description t =
  match get_climate t with
  | None -> "This area has no specific climate data."
  | Some { elevation; temperature; moisture } ->
      let elevation_desc =
        if elevation < -0.5 then "deep underground"
        else if elevation < -0.2 then "underground"
        else if elevation < 0.2 then "at ground level"
        else if elevation < 0.6 then "elevated"
        else "high up"
      in
      let temp_desc =
        if temperature < 0.2 then "freezing"
        else if temperature < 0.4 then "cold"
        else if temperature < 0.6 then "mild"
        else if temperature < 0.8 then "warm"
        else "hot"
      in
      let moisture_desc =
        if moisture < 0.2 then "arid"
        else if moisture < 0.4 then "dry"
        else if moisture < 0.6 then "moderate humidity"
        else if moisture < 0.8 then "humid"
        else "waterlogged"
      in
      Printf.sprintf "You are %s. The air is %s with %s" 
        elevation_desc temp_desc moisture_desc

let get_room_type_description = function
  | Cave -> "You are in a dark cave. The rough stone walls echo with distant sounds."
  | Forest -> "You are in a forest. Trees of varying sizes surround you."
  | Mountain -> "You are on a mountainous outcropping. The winds whip around you."
  | Swamp -> "You are in a swampy area. The ground is soft and wet beneath your feet."
  | Desert -> "You are in a desert region. Sand stretches as far as you can see."
  | Tundra -> "You are in a frozen wasteland. The ground is hard and icy."
  | Lake -> "You are near a body of water. The air is heavy with moisture."
  | Canyon -> "You are in a canyon. Steep walls rise around you."

let get_full_description t =
  let base_desc = match get_room_type t with
    | None -> "This is a nondescript area."
    | Some room_type -> get_room_type_description room_type
  in
  let climate_desc = get_climate_description t in
  base_desc ^ "\n" ^ climate_desc

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

let create_exit ~from_area_id ~to_area_id ~direction ~description ~hidden
    ~locked =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    (* First verify both areas exist *)
    let* from_area = Db.find_opt Q.find_by_id from_area_id in
    let* to_area = Db.find_opt Q.find_by_id to_area_id in
    match (from_area, to_area) with
    | Error e, _ | _, Error e -> Lwt_result.fail e
    | Ok None, _ | _, Ok None -> Lwt_result.return `AreaNotFound
    | Ok (Some _), Ok (Some _) -> (
        let exit =
          {
            from_area_id;
            to_area_id;
            direction;
            description = Option.map ~f:(fun d -> d) description;
            hidden;
            locked;
          }
        in
        match%lwt Db.exec Q.insert_exit exit with
        | Error e -> Lwt_result.fail e
        | Ok () -> Lwt_result.return (`Success exit))
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