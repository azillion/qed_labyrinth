open Base

type t = {
  entity_id: Uuidm.t;
  name: string;
  item_type: Item_definition.item_type;
  properties: Yojson.Safe.t option;
}

type effect = [ `Heal of int ]

let find ~item_entity_id_str =
  let open Lwt_result.Syntax in
  match Uuidm.of_string item_entity_id_str with
  | None -> Lwt_result.fail "Invalid item ID format."
  | Some entity_id ->
      let* item_comp = Ecs.ItemStorage.get entity_id |> Lwt.map (Result.of_option ~error:"Item instance not found in ECS.") in
      let%lwt def_res = Item_definition.find_by_id item_comp.item_definition_id in
      (match def_res with
      | Ok None -> Lwt_result.fail "Item definition not found in database."
      | Ok (Some def) ->
          Lwt_result.return {
            entity_id;
            name = def.name;
            item_type = def.item_type;
            properties = def.properties;
          }
      | Error e -> Lwt_result.fail (Qed_error.to_string e))

let get_name ~(item : t) = item.name

let is_usable ~(item : t) =
  Item_definition.(phys_equal item.item_type Consumable)

let get_effect ~(item : t) =
  let open Yojson.Safe.Util in
  match item.properties with
  | None -> None
  | Some json ->
      match json |> member "heal_amount" |> to_int_option with
      | Some amount -> Some (`Heal amount)
      | None -> None

let get_id ~(item : t) = Uuidm.to_string item.entity_id


let get_slot ~item =
  let open Lwt.Syntax in
  let* item_comp_opt = Ecs.ItemStorage.get item.entity_id in
  match item_comp_opt with
  | None -> Lwt.return Item_definition.None
  | Some item_comp ->
      let* def_res = Item_definition.find_by_id item_comp.item_definition_id in
      (match def_res with
      | Ok (Some def) -> Lwt.return def.slot
      | _ -> Lwt.return Item_definition.None)
