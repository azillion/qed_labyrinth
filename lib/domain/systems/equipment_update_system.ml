open Base

(* Utility to fetch item name by definition id *)
let get_item_name_from_def_id def_id =
  let%lwt def_res = Item_definition.find_by_id def_id in
  match def_res with
  | Ok (Some def) -> Lwt.return (Some def.name)
  | _ -> Lwt.return_none

let get_item_details_from_entity_id entity_id_str =
  match Uuidm.of_string entity_id_str with
  | None -> Lwt.return_none
  | Some entity_id ->
      let%lwt item_comp_opt = Ecs.ItemStorage.get entity_id in
      match item_comp_opt with
      | None -> Lwt.return_none
      | Some item_comp ->
          let%lwt name_opt = get_item_name_from_def_id item_comp.item_definition_id in
          Lwt.return (Option.map name_opt ~f:(fun name -> (entity_id_str, name)))

(* System that watches for changes in equipment or inventory and sends updates to the client. *)
module EquipmentUpdateLogic : System.Tickable = struct
  let name = "equipment-update"

  let execute state =
    let open Lwt_result.Syntax in
    let changed_equipment = Ecs.EquipmentStorage.get_modified () in
    let changed_inventory = Ecs.InventoryStorage.get_modified () in
    let all_changed_entities = List.dedup_and_sort ~compare:Uuidm.compare (changed_equipment @ changed_inventory) in

    let* () =
      Lwt_list.iter_s
        (fun entity_id ->
          let%lwt char_comp_opt = Ecs.CharacterStorage.get entity_id in
          match char_comp_opt with
          | None -> Lwt.return_unit
          | Some char_comp ->
              let user_id = char_comp.user_id in
              let%lwt equip_comp_opt = Ecs.EquipmentStorage.get entity_id in
              let equip_comp = Option.value equip_comp_opt ~default:(Equipment_component.empty (Uuidm.to_string entity_id)) in

              let to_pb_item_opt item_details_opt =
                Option.map item_details_opt ~f:(fun (id, name) ->
                  (Schemas_generated.Output.{ id; name } : Schemas_generated.Output.equipped_item))
              in

              let%lwt main_hand = Option.value_map equip_comp.main_hand ~default:Lwt.return_none ~f:get_item_details_from_entity_id in
              let%lwt off_hand = Option.value_map equip_comp.off_hand ~default:Lwt.return_none ~f:get_item_details_from_entity_id in
              let%lwt head = Option.value_map equip_comp.head ~default:Lwt.return_none ~f:get_item_details_from_entity_id in
              let%lwt chest = Option.value_map equip_comp.chest ~default:Lwt.return_none ~f:get_item_details_from_entity_id in
              let%lwt legs = Option.value_map equip_comp.legs ~default:Lwt.return_none ~f:get_item_details_from_entity_id in
              let%lwt feet = Option.value_map equip_comp.feet ~default:Lwt.return_none ~f:get_item_details_from_entity_id in

              let payload : Schemas_generated.Output.equipment_update = {
                main_hand = to_pb_item_opt main_hand;
                off_hand = to_pb_item_opt off_hand;
                head = to_pb_item_opt head;
                chest = to_pb_item_opt chest;
                legs = to_pb_item_opt legs;
                feet = to_pb_item_opt feet;
              } in

              let event = Schemas_generated.Output.{
                target_user_ids = [ user_id ];
                payload = Equipment_update payload;
                trace_id = "";
              } in
              let%lwt _ = Publisher.publish_event state event in
              Lwt.return_unit)
        all_changed_entities
      |> Error_utils.wrap_ok
    in
    Lwt.return_ok ()
end

module EquipmentUpdate = System.MakeTickable (EquipmentUpdateLogic) 