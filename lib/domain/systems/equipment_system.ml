open Base
open Error_utils
open Qed_error


(* Helper to fetch or initialize equipment component *)
let get_or_create_equipment entity_id =
  let open Lwt_result.Syntax in
  let* equip_opt = wrap_val (Ecs.EquipmentStorage.get entity_id) in
  match equip_opt with
  | Some e -> Lwt_result.return e
  | None ->
      let new_equip = Equipment_component.empty (Uuidm.to_string entity_id) in
      let* () = wrap_ok (Ecs.EquipmentStorage.set entity_id new_equip) in
      Lwt_result.return new_equip

(* --- Equip System --- *)
module EquipLogic : System.S with type event = Event.equip_payload = struct
  let name = "Equip"
  type event = Event.equip_payload
  let event_type = function Event.Equip p -> Some p | _ -> None

  let execute state trace_id ({ user_id; character_id; item_entity_id } : event) =
    let open Lwt_result.Syntax in
    let* char_entity = Item_system.authenticate_character_action state user_id character_id in
    let* item_entity =
      (match Uuidm.of_string item_entity_id with
      | None -> Lwt_result.fail (LogicError "Invalid item entity ID")
      | Some id -> Lwt_result.return id)
    in
    let* inventory = wrap_val (Item_system.get_character_inventory char_entity) in

    if not (List.mem inventory.items item_entity_id ~equal:String.equal) then
      let* () = Publisher.publish_system_message_to_user state ?trace_id user_id "You do not have that item." in
      Lwt_result.return ()
    else
      let* item_comp_opt = wrap_val (Ecs.ItemStorage.get item_entity) in
      match item_comp_opt with
      | None -> Lwt_result.fail (LogicError "Item component not found")
      | Some item_comp ->
          let* item_def_opt = Item_definition.find_by_id item_comp.item_definition_id in
          match item_def_opt with
          | None -> Lwt_result.fail (LogicError "Item definition not found")
          | Some def ->
              if Item_definition.(phys_equal def.slot None) then
                let* () = Publisher.publish_system_message_to_user state ?trace_id user_id "You cannot equip that." in
                Lwt_result.return ()
              else
                let open Fieldslib.Field in
                let slot_field_opt : _ Fieldslib.Field.t option =
                  match def.slot with
                  | MainHand -> Some Equipment_component.Fields.main_hand
                  | OffHand -> Some Equipment_component.Fields.off_hand
                  | Head -> Some Equipment_component.Fields.head
                  | Chest -> Some Equipment_component.Fields.chest
                  | Legs -> Some Equipment_component.Fields.legs
                  | Feet -> Some Equipment_component.Fields.feet
                  | None -> None
                in
                (match slot_field_opt with
                | None ->
                    let* () = Publisher.publish_system_message_to_user state ?trace_id user_id "That item has an invalid equipment slot." in
                    Lwt_result.return ()
                | Some field ->
                    (* Fetch current equipment state *)
                    let* equipment = get_or_create_equipment char_entity in
                    let item_previously_in_slot = get field equipment in

                    (* 1. Unequip the old item (if any) and create the list of items to be in the final inventory *)
                    let items_after_unequip =
                      match item_previously_in_slot with
                      | Some old_item_id -> old_item_id :: inventory.items
                      | None -> inventory.items
                    in

                    (* 2. Remove the new item from the list to be equipped *)
                    let final_inventory_items =
                      Utils.remove_first_item_by_id items_after_unequip item_entity_id
                    in

                    (* 3. Construct the final inventory and equipment states *)
                    let final_inventory = { inventory with items = final_inventory_items } in
                    let final_equipment = fset field equipment (Some item_entity_id) in

                    (* 4. Persist the new state atomically *)
                    let* () = wrap_ok (Ecs.EquipmentStorage.set char_entity final_equipment) in
                    let* () = wrap_ok (Ecs.InventoryStorage.set char_entity final_inventory) in

                    (* 5. Send feedback and trigger updates *)
                    let* () = Publisher.publish_system_message_to_user state ?trace_id user_id ("You equip the " ^ def.name ^ ".") in
                    let* () = wrap_ok (State.enqueue ?trace_id state (Event.RequestInventory { user_id; character_id })) in
                    Lwt_result.return ())
end
module Equip = System.Make (EquipLogic)

(* --- Unequip System --- *)
module UnequipLogic : System.S with type event = Event.unequip_payload = struct
  let name = "Unequip"
  type event = Event.unequip_payload
  let event_type = function Event.Unequip p -> Some p | _ -> None

  let execute state trace_id ({ user_id; character_id; slot } : event) =
    let open Lwt_result.Syntax in
    let* char_entity = Item_system.authenticate_character_action state user_id character_id in
    let* equipment = get_or_create_equipment char_entity in
    let open Fieldslib.Field in
    let slot_field : _ Fieldslib.Field.t option =
      match slot with
      | MainHand -> Some Equipment_component.Fields.main_hand
      | OffHand -> Some Equipment_component.Fields.off_hand
      | Head -> Some Equipment_component.Fields.head
      | Chest -> Some Equipment_component.Fields.chest
      | Legs -> Some Equipment_component.Fields.legs
      | Feet -> Some Equipment_component.Fields.feet
      | None -> None
    in
    match slot_field with
    | None -> Lwt_result.return ()
    | Some field ->
        (match get field equipment with
        | None ->
            let* () = Publisher.publish_system_message_to_user state ?trace_id user_id "You have nothing equipped in that slot." in
            Lwt_result.return ()
        | Some item_id ->
            let updated_equipment = Fieldslib.Field.fset field equipment None in
            let* inventory = wrap_val (Item_system.get_character_inventory char_entity) in
            let updated_inventory = { inventory with items = item_id :: inventory.items } in
            let* () = wrap_ok (Ecs.EquipmentStorage.set char_entity updated_equipment) in
            let* () = wrap_ok (Ecs.InventoryStorage.set char_entity updated_inventory) in
            let item_name_lwt =
              match Uuidm.of_string item_id with
              | None -> Lwt.return "item"
              | Some item_eid ->
                  let%lwt item_comp_opt = Ecs.ItemStorage.get item_eid in
                  match item_comp_opt with
                  | None -> Lwt.return "item"
                  | Some item_comp ->
                      let%lwt res = Item_definition.find_by_id item_comp.item_definition_id in
                      (match res with
                      | Ok (Some d) -> Lwt.return d.name
                      | _ -> Lwt.return "item")
            in
            let* item_name = wrap_val item_name_lwt in
            let* () = Publisher.publish_system_message_to_user state ?trace_id user_id ("You unequip the " ^ item_name ^ ".") in
            (* Request updated inventory list after unequipping *)
            let* () = wrap_ok (State.enqueue ?trace_id state (Event.RequestInventory { user_id; character_id })) in
            Lwt_result.return ())
end
module Unequip = System.Make (UnequipLogic) 