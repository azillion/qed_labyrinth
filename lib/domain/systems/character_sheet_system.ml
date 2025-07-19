open Base
open Error_utils
open Qed_error

(* Helper copied from Item_system for auth *)
let authenticate_character_action (state : State.t) (user_id : string) (character_id : string) =
  let open Lwt_result.Syntax in
  match Uuidm.of_string character_id with
  | None -> Lwt_result.fail InvalidCharacter
  | Some char_uuid -> (
      match State.get_active_character state user_id with
      | Some active_uuid when Uuidm.equal active_uuid char_uuid -> Lwt_result.return char_uuid
      | _ ->
          let* () = wrap_ok (State.enqueue state (Event.ActionFailed { user_id; reason = "You cannot control that character." })) in
          Lwt_result.fail (LogicError "Character action authorization failed"))

module RequestCharacterSheetLogic : System.S with type event = Event.request_character_sheet_payload = struct
  let name = "RequestCharacterSheet"
  type event = Event.request_character_sheet_payload
  let event_type = function Event.RequestCharacterSheet e -> Some e | _ -> None

  let execute state trace_id (p : event) =
    let user_id = p.user_id
    and character_id = p.character_id in
    let open Lwt_result.Syntax in
    let* char_entity = authenticate_character_action state user_id character_id in

    (* Ensure stats are up to date *)
    let* () = Bonus_stat_recalculation_system.recalculate_and_set_bonus_stats char_entity in
    let* () = Character_stat_system.calculate_and_update_stats char_entity in

    (* Fetch components *)
    let* health_opt = wrap_val (Ecs.HealthStorage.get char_entity) in
    let* ap_opt = wrap_val (Ecs.ActionPointsStorage.get char_entity) in
    let* core_stats_opt = wrap_val (Ecs.CoreStatsStorage.get char_entity) in
    let* derived_opt = wrap_val (Ecs.DerivedStatsStorage.get char_entity) in

    match core_stats_opt with
    | None -> Lwt_result.return () (* Should not happen *)
    | Some core_stats ->
        let (health, max_health) = Option.value_map health_opt ~default:(0,0) ~f:(fun h -> (h.current, h.max)) in
        let (ap, max_ap) = Option.value_map ap_opt ~default:(0,0) ~f:(fun ap -> (ap.current, ap.max)) in
        let core_attrs = Types.{ might=core_stats.might; finesse=core_stats.finesse; wits=core_stats.wits; grit=core_stats.grit; presence=core_stats.presence } in
        let derived_stats = Option.value_map derived_opt ~default:Types.{physical_power=0;spell_power=0;accuracy=0;evasion=0;armor=0;resolve=0} ~f:(fun d -> Types.{physical_power=d.physical_power;spell_power=d.spell_power;accuracy=d.accuracy;evasion=d.evasion;armor=d.armor;resolve=d.resolve}) in
        let sheet : Types.character_sheet = { id=character_id; name=""; health; max_health; action_points=ap; max_action_points=max_ap; core_attributes=core_attrs; derived_stats } in
        let of_i = Int32.of_int_exn in
        let pb_core_attrs : Schemas_generated.Output.core_attributes = { might=of_i sheet.core_attributes.might; finesse=of_i sheet.core_attributes.finesse; wits=of_i sheet.core_attributes.wits; grit=of_i sheet.core_attributes.grit; presence=of_i sheet.core_attributes.presence } in
        let pb_derived_stats : Schemas_generated.Output.derived_stats = { physical_power=of_i sheet.derived_stats.physical_power; spell_power=of_i sheet.derived_stats.spell_power; accuracy=of_i sheet.derived_stats.accuracy; evasion=of_i sheet.derived_stats.evasion; armor=of_i sheet.derived_stats.armor; resolve=of_i sheet.derived_stats.resolve } in
        let sheet_msg : Schemas_generated.Output.character_sheet = { id=sheet.id; name=sheet.name; health=of_i sheet.health; max_health=of_i sheet.max_health; action_points=of_i sheet.action_points; max_action_points=of_i sheet.max_action_points; core_attributes=Some pb_core_attrs; derived_stats=Some pb_derived_stats } in
        let output_event : Schemas_generated.Output.output_event = { target_user_ids=[user_id]; payload=Character_sheet sheet_msg; trace_id=Option.value trace_id ~default:"" } in
        let* () = Publisher.publish_event state ?trace_id output_event in
        Lwt_result.return ()
end

module RequestCharacterSheet = System.Make(RequestCharacterSheetLogic) 