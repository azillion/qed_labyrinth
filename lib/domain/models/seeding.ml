open Base

module Internal = struct
  type item_definition_props = {
    id: string;
    name: string;
    description: string;
    item_type: string;
    slot: string;
    weight: float;
    is_stackable: bool;
    properties: Yojson.Safe.t;
  } [@@deriving yojson { strict = false }]

  type area = {
    id : string;
    name : string;
    description : string;
    x : int;
    y : int;
    z : int;
  } [@@deriving yojson { strict = false }]

  type exit = {
    from_id : string;
    to_id : string;
    direction : string;
  } [@@deriving yojson { strict = false }]

  type world = {
    item_definitions : item_definition_props list;
    areas : area list;
    exits : exit list;
  } [@@deriving yojson { strict = false }]
end

type t = Internal.world

let from_file path =
  try
    let json = Yojson.Safe.from_file path in
    Internal.world_of_yojson json
  with
  | Sys_error msg -> Error (Printf.sprintf "Cannot read file: %s" msg)
  | Yojson.Json_error msg -> Error (Printf.sprintf "JSON parsing error: %s" msg)
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _) ->
      Error (Printf.sprintf "JSON structure error: %s" (Exn.to_string exn))

let get_item_definitions world =
  List.map world.Internal.item_definitions ~f:(fun p ->
    let item_type =
      match Item_definition.item_type_of_string p.Internal.item_type with
      | Ok t -> t
      | Error e -> failwith e
    in
    let slot =
      match Item_definition.slot_of_string p.Internal.slot with
      | Ok s -> s
      | Error e -> failwith e
    in
    Item_definition.{
      id = p.Internal.id;
      name = p.Internal.name;
      description = p.Internal.description;
      item_type;
      slot;
      weight = p.Internal.weight;
      is_stackable = p.Internal.is_stackable;
      properties = Some p.Internal.properties;
    }
  )

let get_areas world =
  List.map world.Internal.areas ~f:(fun a -> (a.Internal.id, a.Internal.name, a.Internal.description, a.Internal.x, a.Internal.y, a.Internal.z))

let get_exits world =
  List.map world.Internal.exits ~f:(fun e -> (e.Internal.from_id, e.Internal.to_id, e.Internal.direction)) 