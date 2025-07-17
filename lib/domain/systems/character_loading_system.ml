open Base
open Qed_error
open Error_utils

module LoadCharacterLogic : System.S with type event = Event.load_character_into_ecs_payload = struct
  let name = "character-load"
  type event = Event.load_character_into_ecs_payload
  let event_type = function Event.LoadCharacterIntoECS e -> Some e | _ -> None

  let execute state trace_id payload =
    (* let user_id = (payload : event).user_id in *)
    let character_id = (payload : event).character_id in
    let open Lwt_result.Syntax in
    let* character_opt = Character.find_by_id character_id in
    match character_opt with
    | None -> Lwt_result.fail CharacterNotFound
    | Some character ->
        match Uuidm.of_string character.id with
        | None -> Lwt_result.fail InvalidCharacter
        | Some entity_id ->
            let* () =
              match%lwt Ecs.Entity.ensure_exists entity_id with
              | Ok () -> Lwt_result.return ()
              | Error e -> Lwt_result.fail (DatabaseError (Base.Error.to_string_hum e))
            in
            let char_comp = Components.CharacterComponent.{ entity_id = character.id; user_id = character.user_id } in
            let* () = wrap_ok (Ecs.CharacterStorage.set entity_id char_comp) in

            let core_stats_comp = Components.CoreStatsComponent.{
              entity_id = character.id;
              might = character.core_stats.might;
              finesse = character.core_stats.finesse;
              wits = character.core_stats.wits;
              grit = character.core_stats.grit;
              presence = character.core_stats.presence;
            } in
            let* () = wrap_ok (Ecs.CoreStatsStorage.set entity_id core_stats_comp) in
            
            let* pos_opt = wrap_val (Ecs.CharacterPositionStorage.get entity_id) in
            let* () = match pos_opt with
              | Some _ -> Lwt_result.return ()
              | None ->
                  let pos_comp = Components.CharacterPositionComponent.{ entity_id = character.id; area_id = "00000000-0000-0000-0000-000000000000" } in
                  wrap_ok (Ecs.CharacterPositionStorage.set entity_id pos_comp)
            in

            let* () = Character_stat_system.calculate_and_update_stats entity_id in
            let* health_opt = wrap_val (Ecs.HealthStorage.get entity_id) in
            let* ap_opt = wrap_val (Ecs.ActionPointsStorage.get entity_id) in
            let* derived_opt = wrap_val (Ecs.DerivedStatsStorage.get entity_id) in

            let (health, max_health) = Option.value_map health_opt ~default:(0,0) ~f:(fun h -> (h.current, h.max)) in
            let (ap, max_ap) = Option.value_map ap_opt ~default:(0,0) ~f:(fun ap -> (ap.current, ap.max)) in
            
            let core_attrs = Types.{ might=core_stats_comp.might; finesse=core_stats_comp.finesse; wits=core_stats_comp.wits; grit=core_stats_comp.grit; presence=core_stats_comp.presence } in
            let derived_stats = Option.value_map derived_opt ~default:Types.{physical_power=0;spell_power=0;accuracy=0;evasion=0;armor=0;resolve=0} ~f:(fun d -> Types.{physical_power=d.physical_power;spell_power=d.spell_power;accuracy=d.accuracy;evasion=d.evasion;armor=d.armor;resolve=d.resolve}) in

            let sheet : Types.character_sheet = { id=character.id; name=character.name; health;max_health;action_points=ap;max_action_points=max_ap;core_attributes=core_attrs;derived_stats } in
            State.set_active_character state ~user_id:character.user_id ~entity_id;
            
            let of_i = Int32.of_int_exn in
            let pb_core_attrs : Schemas_generated.Output.core_attributes = { might=of_i sheet.core_attributes.might;finesse=of_i sheet.core_attributes.finesse;wits=of_i sheet.core_attributes.wits;grit=of_i sheet.core_attributes.grit;presence=of_i sheet.core_attributes.presence } in
            let pb_derived_stats : Schemas_generated.Output.derived_stats = { physical_power=of_i sheet.derived_stats.physical_power;spell_power=of_i sheet.derived_stats.spell_power;accuracy=of_i sheet.derived_stats.accuracy;evasion=of_i sheet.derived_stats.evasion;armor=of_i sheet.derived_stats.armor;resolve=of_i sheet.derived_stats.resolve } in
            let sheet_msg : Schemas_generated.Output.character_sheet = { id=sheet.id;name=sheet.name;health=of_i sheet.health;max_health=of_i sheet.max_health;action_points=of_i sheet.action_points;max_action_points=of_i sheet.max_action_points;core_attributes=Some pb_core_attrs;derived_stats=Some pb_derived_stats } in
            let output_event : Schemas_generated.Output.output_event = { target_user_ids=[character.user_id]; payload=Character_sheet sheet_msg; trace_id="" } in
            
            let* () = Publisher.publish_event state ?trace_id output_event in
            (* Determine which area to load for the player.  If the character already has a
               stored position, honour that; otherwise fall back to the default starting
               area. *)
            let area_id =
              match pos_opt with
              | Some pos -> pos.area_id
              | None -> "00000000-0000-0000-0000-000000000000"
            in
            let* () = wrap_ok (State.enqueue ?trace_id state (Event.AreaQuery { user_id=character.user_id; area_id })) in
            Lwt_result.return ()
end
module LoadCharacter = System.Make(LoadCharacterLogic)