open Base

type t = { entity_id: Uuidm.t; user_id: string }

let get_id ~character = Uuidm.to_string character.entity_id

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

