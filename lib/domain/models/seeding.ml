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

  type item_in_area = { item_definition_id: string; quantity: int }

  (* Manual parser to accept either string or object *)
  let item_in_area_of_yojson json =
    match json with
    | `String id -> Ok { item_definition_id = id; quantity = 1 }
    | `Assoc _ as j -> (
        match j with
        | `Assoc kv -> (
            let id_opt = List.Assoc.find kv ~equal:String.equal "item_definition_id" |> Option.map ~f:(function `String s -> s | _ -> "") in
            let qty = match List.Assoc.find kv ~equal:String.equal "quantity" with Some (`Int n) -> n | _ -> 1 in
            match id_opt with
            | Some id -> Ok { item_definition_id = id; quantity = qty }
            | None -> Error "missing id")
        | _ -> Error "invalid obj")
    | _ -> Error "Invalid item_in_area"

  let item_in_area_to_yojson (i : item_in_area) =
    `Assoc [ ("item_definition_id", `String i.item_definition_id); ("quantity", `Int i.quantity) ]

  type area = {
    id : string;
    name : string;
    description : string;
    x : int;
    y : int;
    z : int;
    items : item_in_area list [@default []];
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
    lore_card_templates : lore_card_template list [@default []];
  } [@@deriving yojson { strict = false }]

  and lore_card_template = {
    id : string;
    card_name : string;
    power_cost : int;
    required_saga_tier : int;
    bonus_1_type : string option;
    bonus_1_value : int option;
    bonus_2_type : string option;
    bonus_2_value : int option;
    bonus_3_type : string option;
    bonus_3_value : int option;
    grants_ability : string option;
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
  List.map world.Internal.areas ~f:(fun a ->
    let item_data = List.map a.Internal.items ~f:(fun i -> (i.item_definition_id, i.quantity, a.id)) in
    (a.id, a.name, a.description, a.x, a.y, a.z, item_data)
  )

let get_exits world =
  List.map world.Internal.exits ~f:(fun e -> (e.Internal.from_id, e.Internal.to_id, e.Internal.direction)) 

let get_lore_card_templates world =
  List.map world.Internal.lore_card_templates ~f:(fun (t : Internal.lore_card_template) ->
    ( t.id, t.card_name, t.power_cost, t.required_saga_tier,
      t.bonus_1_type, t.bonus_1_value,
      t.bonus_2_type, t.bonus_2_value,
      t.bonus_3_type, t.bonus_3_value,
      t.grants_ability )) 