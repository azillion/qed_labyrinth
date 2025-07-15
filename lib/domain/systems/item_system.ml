open Base
open Qed_error
open Error_utils

module System = struct

  (* TODO: This is a temporary function to authenticate the character action.
   * It will be replaced with a proper authentication system in the future. *)
  (* Permission check: ensure the user is commanding their active character *)
  let authenticate_character_action (state : State.t) (user_id : string) (character_id : string) =
    let open Lwt_result.Syntax in
    match Uuidm.of_string character_id with
    | None -> Lwt_result.fail InvalidCharacter
    | Some char_uuid -> (
        match State.get_active_character state user_id with
        | Some active_uuid when Uuidm.equal active_uuid char_uuid -> Lwt_result.return char_uuid
        | _ ->
            let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.ActionFailed { user_id; reason = "You cannot control that character." })) in
            Lwt_result.fail (LogicError "Character action authorization failed"))

  (* Retrieve the character's inventory or create an empty one if none exists *)
  let get_character_inventory (char_entity : Uuidm.t) =
    let%lwt inventory_opt = Ecs.InventoryStorage.get char_entity in
    let inventory =
      Option.value inventory_opt ~default:Components.InventoryComponent.{
        entity_id = Uuidm.to_string char_entity;
        items = [];
      }
    in
    Lwt.return inventory

  (* Handle picking up an item from the ground *)
  let handle_take_item state user_id character_id item_entity_id =
    let open Lwt_result.Syntax in
    let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[ITEM] User %s requests to take item %s" user_id item_entity_id)) in

    let* char_entity = authenticate_character_action state user_id character_id in

    let* item_entity =
      Uuidm.of_string item_entity_id |> Lwt.return |> Lwt.map (Result.of_option ~error:(LogicError "Invalid item entity ID"))
    in

    let* char_pos = Ecs.CharacterPositionStorage.get char_entity |> Lwt.map (Result.of_option ~error:(LogicError "Character has no position")) in
    let* item_pos_opt = wrap_val (Ecs.ItemPositionStorage.get item_entity) in

    match item_pos_opt with
    | Some item_pos when String.equal item_pos.area_id char_pos.area_id ->
        let* () = wrap_ok (Ecs.ItemPositionStorage.remove item_entity) in
        let* inventory = wrap_val (get_character_inventory char_entity) in
        let updated_inventory = { inventory with items = item_entity_id :: inventory.items } in
        let* () = wrap_ok (Ecs.InventoryStorage.set char_entity updated_inventory) in
        let* () = Publisher.publish_system_message_to_user state user_id "You take the item." in
        let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.RequestInventory { user_id; character_id })) in
        let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.AreaQuery { user_id; area_id = char_pos.area_id })) in
        Lwt_result.return ()
    | _ ->
        let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.ActionFailed { user_id; reason = "The item is not here." })) in
        Lwt_result.return ()

  (* Handle dropping an item from inventory to the ground *)
  let handle_drop_item state user_id character_id item_entity_id =
    let open Lwt_result.Syntax in
    let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[ITEM] User %s requests to drop item %s" user_id item_entity_id)) in

    let* char_entity = authenticate_character_action state user_id character_id in

    let* inventory = wrap_val (get_character_inventory char_entity) in

    if not (List.exists inventory.items ~f:(String.equal item_entity_id)) then (
      let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.ActionFailed { user_id; reason = "You do not have that item." })) in
      Lwt_result.return ()
    ) else
      let updated_inventory = { inventory with items = List.filter inventory.items ~f:(fun id -> not (String.equal id item_entity_id)) } in
      let* () = wrap_ok (Ecs.InventoryStorage.set char_entity updated_inventory) in

      let* char_pos = Ecs.CharacterPositionStorage.get char_entity |> Lwt.map (Result.of_option ~error:(LogicError "Character has no position")) in

      let* item_entity =
        Uuidm.of_string item_entity_id |> Lwt.return |> Lwt.map (Result.of_option ~error:(LogicError "Invalid item entity ID"))
      in
      let new_item_pos = Components.ItemPositionComponent.{
        entity_id = item_entity_id;
        area_id = char_pos.area_id;
      } in
      let* () = wrap_ok (Ecs.ItemPositionStorage.set item_entity new_item_pos) in
      let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[DROP] inserted ItemPosition (%s → %s)" item_entity_id char_pos.area_id)) in

      let* () = Publisher.publish_system_message_to_user state user_id "You drop the item." in
      let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.RequestInventory { user_id; character_id })) in
      let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.AreaQuery { user_id; area_id = char_pos.area_id })) in
      Lwt_result.return ()

  (* Build inventory details and queue SendInventory event *)
  let handle_request_inventory state user_id character_id =
    let open Lwt_result.Syntax in
    let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[ITEM] Handling inventory request for user %s" user_id)) in

    let* char_entity = authenticate_character_action state user_id character_id in
    let* inventory = wrap_val (get_character_inventory char_entity) in

    (* Helper to resolve an item entity to details *)
    let build_item_details (item_eid_str : string) : (string * string * string * int) option Lwt.t =
      match Uuidm.of_string item_eid_str with
      | None -> Lwt.return_none
      | Some item_eid ->
          let%lwt item_comp_opt = Ecs.ItemStorage.get item_eid in
          (match item_comp_opt with
          | None -> Lwt.return_none
          | Some item_comp ->
              let%lwt def_res = Item_definition.find_by_id item_comp.item_definition_id in
              (match def_res with
              | Ok (Some def) -> Lwt.return_some (item_eid_str, def.name, def.description, item_comp.quantity)
              | _ -> Lwt.return_none))
    in

    let* detail_options = wrap_val (Lwt_list.map_s build_item_details inventory.items) in
    let successful_items = List.filter_map detail_options ~f:Fn.id in
    let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.SendInventory { user_id; items = successful_items })) in
    Lwt_result.return ()
end 