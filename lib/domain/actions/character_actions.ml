open Base

type t = { entity_id: Uuidm.t; user_id: string }

let get_id ~character = Uuidm.to_string character.entity_id

let of_ids ~entity_id ~user_id : t = { entity_id; user_id }

let find_active ~state ~user_id =
  match State.get_active_character state user_id with
  | None -> Lwt_result.fail "You do not have an active character."
  | Some entity_id -> Lwt_result.return { entity_id; user_id }

let get_name ~character =
  let open Lwt_result.Syntax in
  let char_id_str = Uuidm.to_string character.entity_id in
  let* char_opt = Character.find_by_id char_id_str () in
  match char_opt with
  | Some c -> Lwt_result.return c.name
  | None -> Lwt_result.fail Qed_error.CharacterNotFound

let get_health ~character =
  let%lwt health_opt = Ecs.HealthStorage.get character.entity_id in
  Lwt.return (Option.map health_opt ~f:(fun h -> (h.current, h.max)))

let get_action_points ~character =
  let%lwt ap_opt = Ecs.ActionPointsStorage.get character.entity_id in
  Lwt.return (Option.map ap_opt ~f:(fun ap -> (ap.current, ap.max)))

let get_core_stats ~character =
  let%lwt core_opt = Ecs.CoreStatsStorage.get character.entity_id in
  Lwt.return (Option.map core_opt ~f:(fun c ->
    Types.{ might=c.might; finesse=c.finesse; wits=c.wits; grit=c.grit; presence=c.presence }))

let get_derived_stats ~character =
  let%lwt derived_opt = Ecs.DerivedStatsStorage.get character.entity_id in
  Lwt.return (Option.map derived_opt ~f:(fun d ->
    Types.{physical_power=d.physical_power; spell_power=d.spell_power; accuracy=d.accuracy; evasion=d.evasion; armor=d.armor; resolve=d.resolve}))

let get_progression ~character =
  let%lwt prog_opt = Ecs.ProgressionStorage.get character.entity_id in
  Lwt.return (Option.map prog_opt ~f:(fun p -> (p.proficiency_level, p.power_budget)))

let send_message ~state ~character ~message =
  Publisher.publish_system_message_to_user state character.user_id message

let refresh_client_ui ~state ~character =
  let open Lwt_result.Syntax in
  let char_id_str = get_id ~character in
  let* () = Error_utils.wrap_ok (State.enqueue state (Event.RequestInventory { user_id = character.user_id; character_id = char_id_str })) in
  let* () = Error_utils.wrap_ok (State.enqueue state (Event.RequestCharacterSheet { user_id = character.user_id; character_id = char_id_str })) in
  Lwt_result.return ()

let get_area ~character =
  let open Lwt_result.Syntax in
  let* pos_comp = Ecs.CharacterPositionStorage.get character.entity_id
    |> Lwt.map (Result.of_option ~error:"Character has no position component.")
  in
  Area_actions.find_by_id ~area_id_str:pos_comp.area_id

let get_inventory ~character =
  let open Lwt_result.Syntax in
  let* inventory_opt = Error_utils.wrap_val (Ecs.InventoryStorage.get character.entity_id) in
  let inventory = Option.value inventory_opt ~default:Components.InventoryComponent.{
    entity_id = get_id ~character;
    items = [];
  } in
  Lwt_result.return inventory

let take ~state ~character ~item =
  let open Lwt_result.Syntax in
  let* current_area = get_area ~character in
  (* Verify item is in the current area before proceeding *)
  let* _ = Area_actions.find_item ~area:current_area ~item_id_str:(Item_actions.get_id ~item) in

  (* Perform the actions *)
  let* () = Area_actions.remove_item ~area:current_area ~item in
  let* inventory_comp =
    Error_utils.wrap_val (Ecs.InventoryStorage.get character.entity_id)
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
    |> Lwt.map (Result.map ~f:(Option.value ~default:
        (Components.InventoryComponent.{entity_id = get_id ~character; items = []})))
  in
  let updated_inventory = { inventory_comp with items = (Item_actions.get_id ~item) :: inventory_comp.items } in
  let* () = Error_utils.wrap_ok (Ecs.InventoryStorage.set character.entity_id updated_inventory)
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in

  (* Send feedback and refresh UI *)
  let* () = send_message ~state ~character ~message:("You take the " ^ (Item_actions.get_name ~item) ^ ".")
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
  in
  let* () = refresh_client_ui ~state ~character |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
  let* () = Error_utils.wrap_ok (State.enqueue state (Event.AreaQuery { user_id = character.user_id; area_id = Area_actions.get_id current_area }))
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
  Lwt_result.return ()

let drop ~state ~character ~item =
  let open Lwt_result.Syntax in
  let* inventory_comp = Ecs.InventoryStorage.get character.entity_id
    |> Lwt.map (Result.of_option ~error:"You have no items to drop.")
  in
  let item_id_str = Item_actions.get_id ~item in
  if not (List.mem inventory_comp.items item_id_str ~equal:String.equal) then
    Lwt_result.fail "You do not have that item."
  else
    let* current_area = get_area ~character in
    (* Perform the actions *)
    let updated_inventory = { inventory_comp with items = Utils.remove_first_item_by_id inventory_comp.items item_id_str } in
    let* () = Error_utils.wrap_ok (Ecs.InventoryStorage.set character.entity_id updated_inventory)
      |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
    let* () = Area_actions.add_item ~area:current_area ~item in

    (* Send feedback and refresh UI *)
    let* () = send_message ~state ~character ~message:("You drop the " ^ (Item_actions.get_name ~item) ^ ".")
      |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
    in
    let* () = refresh_client_ui ~state ~character |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
    let* () = Error_utils.wrap_ok (State.enqueue state (Event.AreaQuery { user_id = character.user_id; area_id = Area_actions.get_id current_area }))
      |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
    Lwt_result.return ()

let use ~state:_ ~(character : t) ~(item : Item_actions.t) =
  let%lwt inventory_comp_opt = Ecs.InventoryStorage.get character.entity_id in
  let inventory_comp = Option.value inventory_comp_opt
    ~default:Components.InventoryComponent.{entity_id = get_id ~character; items = []}
  in
  let has_item =
    List.mem inventory_comp.items (Item_actions.get_id ~item) ~equal:String.equal
  in

  if not has_item then Lwt.return (Error "You don't have that item.")
  else if not (Item_actions.is_usable ~item) then Lwt.return (Error "You cannot use that item.")
  else
    match Item_actions.get_effect ~item with
    | Some (`Heal amount) ->
        let%lwt health_comp_opt = Ecs.HealthStorage.get character.entity_id in
        (match health_comp_opt with
        | Some hc ->
            let new_health = Int.min hc.max (hc.current + amount) in
            let%lwt () =
              if new_health = hc.current then Lwt.return_unit
              else Ecs.HealthStorage.set character.entity_id { hc with current = new_health }
            in
            let updated_items = Utils.remove_first_item_by_id inventory_comp.items (Item_actions.get_id ~item) in
            let%lwt () = Ecs.InventoryStorage.set character.entity_id { inventory_comp with items = updated_items } in
            Lwt.return (Ok ("You use the " ^ (Item_actions.get_name ~item) ^ " and feel refreshed."))
        | None ->
            let updated_items = Utils.remove_first_item_by_id inventory_comp.items (Item_actions.get_id ~item) in
            let%lwt () = Ecs.InventoryStorage.set character.entity_id { inventory_comp with items = updated_items } in
            Lwt.return (Ok ("You use the " ^ (Item_actions.get_name ~item) ^ ".")))
    | None -> Lwt.return (Error "That item has no usable effect.")

let get_area ~character =
  let open Lwt_result.Syntax in
  let* pos_comp = Ecs.CharacterPositionStorage.get character.entity_id
    |> Lwt.map (Result.of_option ~error:"Character has no position component.")
  in
  Area_actions.find_by_id ~area_id_str:pos_comp.area_id

let move ~state ~character ~direction =
  let open Lwt_result.Syntax in
  let* current_area = get_area ~character in
  let* exit_record = Area_actions.find_exit ~area:current_area ~direction in

  let old_area_id = Area_actions.get_id current_area in
  let new_area_id = exit_record.to_area_id in

  let* char_name = get_name ~character |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
  let direction_str = Components.ExitComponent.direction_to_string direction in
  let departure_msg_content = Printf.sprintf "%s has left, heading %s." char_name direction_str in
  let* departure_msg = Communication.create ~message_type:System ~sender_id:None ~content:departure_msg_content ~area_id:(Some old_area_id)
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
  in
  let* () = Error_utils.wrap_ok (State.enqueue state (Event.Announce { area_id = old_area_id; message = departure_msg })) |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in

  let* () =
    let* pos_comp = Ecs.CharacterPositionStorage.get character.entity_id |> Lwt.map (Result.of_option ~error:"Position component missing") in
    let new_pos_comp = { pos_comp with area_id = new_area_id } in
    Error_utils.wrap_ok (Ecs.CharacterPositionStorage.set character.entity_id new_pos_comp) |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
  in

  let* () = Error_utils.wrap_ok (State.enqueue state
    (Event.PlayerMoved { user_id = character.user_id; old_area_id; new_area_id; direction })) |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
  in
  Lwt_result.return ()

let equip ~state ~character ~item =
  let open Lwt_result.Syntax in
  let* inventory = get_inventory ~character |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
  let item_id_str = Item_actions.get_id ~item in

  if not (List.mem inventory.items item_id_str ~equal:String.equal) then
    Lwt_result.fail "You do not have that item."
  else
    let* slot = Error_utils.wrap_val (Item_actions.get_slot ~item)
      |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
    in
    if Item_definition.(phys_equal slot None) then
      Lwt_result.fail "You cannot equip that."
    else
      let open Fieldslib.Field in
      let slot_field_opt : _ Fieldslib.Field.t option =
        match slot with
        | Item_definition.MainHand -> Some Equipment_component.Fields.main_hand
        | Item_definition.OffHand  -> Some Equipment_component.Fields.off_hand
        | Item_definition.Head     -> Some Equipment_component.Fields.head
        | Item_definition.Chest    -> Some Equipment_component.Fields.chest
        | Item_definition.Legs     -> Some Equipment_component.Fields.legs
        | Item_definition.Feet     -> Some Equipment_component.Fields.feet
        | Item_definition.None     -> None
      in
      (match slot_field_opt with
      | None -> Lwt_result.fail "That item has an invalid equipment slot."
      | Some field ->
          let* equipment =
            Error_utils.wrap_val (Ecs.EquipmentStorage.get character.entity_id)
            |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
            |> Lwt.map (Result.map ~f:(Option.value ~default:(Equipment_component.empty (get_id ~character))))
          in
          let item_previously_in_slot = get field equipment in

          (* 1. Unequip old item (if any) and add to inventory list *)
          let items_after_unequip =
            match item_previously_in_slot with
            | Some old_item_id -> old_item_id :: inventory.items
            | None -> inventory.items
          in

          (* 2. Remove the new item from the list *)
          let final_inventory_items = Utils.remove_first_item_by_id items_after_unequip item_id_str in

          (* 3. Construct final states *)
          let final_inventory = { inventory with items = final_inventory_items } in
          let final_equipment = fset field equipment (Some item_id_str) in

          (* 4. Persist states *)
          let* () = Error_utils.wrap_ok (Ecs.EquipmentStorage.set character.entity_id final_equipment)
            |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
          let* () = Error_utils.wrap_ok (Ecs.InventoryStorage.set character.entity_id final_inventory)
            |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in

          (* 5. Fire event *)
          let* () = Error_utils.wrap_ok (State.enqueue state (Event.LoadoutChanged { character_id = get_id ~character }))
            |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
          Lwt_result.return () )

let unequip ~state ~character ~slot =
  let open Lwt_result.Syntax in
  let open Fieldslib.Field in
  let slot_field_opt : _ Fieldslib.Field.t option =
    match slot with
    | Item_definition.MainHand -> Some Equipment_component.Fields.main_hand
    | Item_definition.OffHand  -> Some Equipment_component.Fields.off_hand
    | Item_definition.Head     -> Some Equipment_component.Fields.head
    | Item_definition.Chest    -> Some Equipment_component.Fields.chest
    | Item_definition.Legs     -> Some Equipment_component.Fields.legs
    | Item_definition.Feet     -> Some Equipment_component.Fields.feet
    | Item_definition.None     -> None
  in
  match slot_field_opt with
  | None -> Lwt_result.fail "Invalid slot specified."
  | Some field ->
      let* equipment =
        Error_utils.wrap_val (Ecs.EquipmentStorage.get character.entity_id)
        |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
        |> Lwt.map (Result.map ~f:(Option.value ~default:(Equipment_component.empty (get_id ~character))))
      in
      (match get field equipment with
      | None -> Lwt_result.fail "You have nothing equipped in that slot."
      | Some item_id_str ->
          let updated_equipment = fset field equipment None in
          let* inventory = get_inventory ~character |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
          let updated_inventory = { inventory with items = item_id_str :: inventory.items } in

          (* Persist state *)
          let* () = Error_utils.wrap_ok (Ecs.EquipmentStorage.set character.entity_id updated_equipment)
            |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
          let* () = Error_utils.wrap_ok (Ecs.InventoryStorage.set character.entity_id updated_inventory)
            |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in

          (* Fire event *)
          let* () = Error_utils.wrap_ok (State.enqueue state (Event.LoadoutChanged { character_id = get_id ~character }))
            |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
          Lwt_result.return () )

let say ~state ~character ~content =
  let open Lwt_result.Syntax in
  let* current_area = get_area ~character in
  let area_id_str = Area_actions.get_id current_area in
  let sender_char_id_str = Some (get_id ~character) in

  let* message = Communication.create
    ~message_type:Chat
    ~sender_id:sender_char_id_str
    ~content
    ~area_id:(Some area_id_str)
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
  in

  let* () = Error_utils.wrap_ok (State.enqueue state (Event.Announce { area_id = area_id_str; message }))
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
  in
  Lwt_result.return ()

