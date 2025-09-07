open Base
open Error_utils

(* Helper copied from Item_system for auth *)
(* authenticate_character_action removed in favor of facade *)

module RequestCharacterSheetLogic : System.S with type event = Event.request_character_sheet_payload = struct
  let name = "RequestCharacterSheet"
  type event = Event.request_character_sheet_payload
  let event_type = function Event.RequestCharacterSheet e -> Some e | _ -> None

  let execute state trace_id (p : event) =
    let user_id = p.user_id in
    let open Lwt_result.Syntax in
    let* character = Character_actions.find_active ~state ~user_id |> Lwt.map (Result.map_error ~f:(fun s -> Qed_error.LogicError s)) in

    (* Fetch all data via the new facade *)
    let* name = Character_actions.get_name ~character in
    let* health, max_health = wrap_val (Character_actions.get_health ~character) |> Lwt.map (Result.map ~f:(Option.value ~default:(0,0))) in
    let* ap, max_ap = wrap_val (Character_actions.get_action_points ~character) |> Lwt.map (Result.map ~f:(Option.value ~default:(0,0))) in
    let* core_attrs = wrap_val (Character_actions.get_core_stats ~character) |> Lwt.map (Result.map ~f:(Option.value ~default:Types.{might=0;finesse=0;wits=0;grit=0;presence=0})) in
    let* derived_stats = wrap_val (Character_actions.get_derived_stats ~character) |> Lwt.map (Result.map ~f:(Option.value ~default:Types.{physical_power=0;spell_power=0;accuracy=0;evasion=0;armor=0;resolve=0})) in
    let* prof_lvl, p_budget = wrap_val (Character_actions.get_progression ~character) |> Lwt.map (Result.map ~f:(Option.value ~default:(1,0))) in

    (* Build and publish the protobuf message *)
    let of_i = Int32.of_int_exn in
    let pb_core_attrs : Schemas_generated.Output.core_attributes = { might=of_i core_attrs.might; finesse=of_i core_attrs.finesse; wits=of_i core_attrs.wits; grit=of_i core_attrs.grit; presence=of_i core_attrs.presence } in
    let pb_derived_stats : Schemas_generated.Output.derived_stats = { physical_power=of_i derived_stats.physical_power; spell_power=of_i derived_stats.spell_power; accuracy=of_i derived_stats.accuracy; evasion=of_i derived_stats.evasion; armor=of_i derived_stats.armor; resolve=of_i derived_stats.resolve } in
    
    let sheet_msg : Schemas_generated.Output.character_sheet = {
      id = Character_actions.get_id ~character;
      name;
      health = of_i health;
      max_health = of_i max_health;
      action_points = of_i ap;
      max_action_points = of_i max_ap;
      core_attributes = Some pb_core_attrs;
      derived_stats = Some pb_derived_stats;
      proficiency_level = of_i prof_lvl;
      power_budget = of_i p_budget;
    } in
    let output_event : Schemas_generated.Output.output_event = { target_user_ids=[user_id]; payload=Character_sheet sheet_msg; trace_id=Option.value trace_id ~default:"" } in
    let* () = Publisher.publish_event state ?trace_id output_event in
    Lwt_result.return ()
end

module RequestCharacterSheet = System.Make(RequestCharacterSheetLogic) 