open Qed_error
open Error_utils

let handle_load_character state character_id =
  let open Lwt_result.Syntax in
  
  (* Call Character.find_by_id to get relational data from Tier 1 *)
  let* character_opt = Character.find_by_id character_id in
  match character_opt with
  | None -> Lwt_result.fail CharacterNotFound
  | Some character ->
      (* Convert character_id string to Uuidm.t entity ID *)
      match Uuidm.of_string character_id with
      | None -> Lwt_result.fail InvalidCharacter
      | Some entity_id ->
          (* Ensure entity exists in ECS before attaching components *)
          let* () = Ecs.Entity.ensure_exists entity_id |> Lwt.map (Result.map_error (fun e -> DatabaseError (Base.Error.to_string_hum e))) in
          
          (* Store CharacterComponent to link user to entity *)
          let character_component = Components.CharacterComponent.{
            entity_id = character_id;
            user_id = character.user_id;
          } in
          let* () = wrap_ok (Ecs.CharacterStorage.set entity_id character_component) in

          (* Core stats *)
          let core_stats_component = Components.CoreStatsComponent.{
            entity_id = character_id;
            might = character.core_stats.might;
            finesse = character.core_stats.finesse;
            wits = character.core_stats.wits;
            grit = character.core_stats.grit;
            presence = character.core_stats.presence;
          } in
          let* () = wrap_ok (Ecs.CoreStatsStorage.set entity_id core_stats_component) in
          
          (* Load or create CharacterPositionComponent *)
          let* pos_opt = wrap_val (Ecs.CharacterPositionStorage.get entity_id) in
          let* () = match pos_opt with
            | Some _ -> Lwt_result.return () (* Position already exists *)
            | None ->
                (* Create new position pointing to default starting area *)
                let position_component = Components.CharacterPositionComponent.{
                  entity_id = character_id;
                  area_id = "00000000-0000-0000-0000-000000000000";
                } in
                wrap_ok (Ecs.CharacterPositionStorage.set entity_id position_component)
          in
          let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[LOAD] Position set for %s in area %s\n" character_id "000...000")) in
          
          (* Call calculate_and_update_stats to compute derived stats *)
          let* () = Character_stat_system.calculate_and_update_stats entity_id in
          
          (* Construct Types.character_sheet record from loaded components *)
          let* _position_opt = wrap_val (Ecs.CharacterPositionStorage.get entity_id) in
          
          (* Get the components that were just created by calculate_and_update_stats *)
          let* health_opt = wrap_val (Ecs.HealthStorage.get entity_id) in
          let* action_points_opt = wrap_val (Ecs.ActionPointsStorage.get entity_id) in
          let* derived_stats_opt = wrap_val (Ecs.DerivedStatsStorage.get entity_id) in
          
          let character_name = character.name in
          
          let (health, max_health) = match health_opt with
            | Some h -> (h.current, h.max)
            | None -> (100, 100) (* Fallback values *)
          in
          
          let (action_points, max_action_points) = match action_points_opt with
            | Some ap -> (ap.current, ap.max)
            | None -> (100, 100) (* Fallback values *)
          in
          
          let core_attributes = Types.{
              might = core_stats_component.Components.CoreStatsComponent.might;
              finesse = core_stats_component.finesse;
              wits = core_stats_component.wits;
              grit = core_stats_component.grit;
              presence = core_stats_component.presence;
            } in
          
          let derived_stats = match derived_stats_opt with
            | Some ds -> Types.{
                physical_power = ds.Components.DerivedStatsComponent.physical_power;
                spell_power = ds.spell_power;
                accuracy = ds.accuracy;
                evasion = ds.evasion;
                armor = ds.armor;
                resolve = ds.resolve;
              }
            | None -> Types.{ physical_power = 0; spell_power = 0; accuracy = 0; evasion = 0; armor = 0; resolve = 0 } (* Fallback *)
          in
          
          let character_sheet : Types.character_sheet = {
            id = character_id;
            name = character_name;
            health;
            max_health;
            action_points;
            max_action_points;
            core_attributes;
            derived_stats;
          } in
          
          (* Track as active character *)
          State.set_active_character state ~user_id:character.user_id ~entity_id;

          (* Publish CharacterSheet protobuf event to user *)
          let of_i = Int32.of_int in
          let pb_core_attributes : Schemas_generated.Output.core_attributes = {
            might = of_i character_sheet.core_attributes.might;
            finesse = of_i character_sheet.core_attributes.finesse;
            wits = of_i character_sheet.core_attributes.wits;
            grit = of_i character_sheet.core_attributes.grit;
            presence = of_i character_sheet.core_attributes.presence;
          } in

          let pb_derived_stats : Schemas_generated.Output.derived_stats = {
            physical_power = of_i character_sheet.derived_stats.physical_power;
            spell_power = of_i character_sheet.derived_stats.spell_power;
            accuracy = of_i character_sheet.derived_stats.accuracy;
            evasion = of_i character_sheet.derived_stats.evasion;
            armor = of_i character_sheet.derived_stats.armor;
            resolve = of_i character_sheet.derived_stats.resolve;
          } in

          let character_sheet_msg : Schemas_generated.Output.character_sheet = {
            id = character_sheet.id;
            name = character_sheet.name;
            health = of_i character_sheet.health;
            max_health = of_i character_sheet.max_health;
            action_points = of_i character_sheet.action_points;
            max_action_points = of_i character_sheet.max_action_points;
            core_attributes = Some pb_core_attributes;
            derived_stats = Some pb_derived_stats;
          } in

          let output_event : Schemas_generated.Output.output_event = {
            target_user_ids = [character.user_id];
            payload = Character_sheet character_sheet_msg;
            trace_id = "";
          } in

          let* () = Publisher.publish_event state output_event in
          
          (* Also send AreaQuery for client to receive area details & chat *)
          let area_id = match _position_opt with
            | Some pos -> pos.Components.CharacterPositionComponent.area_id
            | None -> "00000000-0000-0000-0000-000000000000" in
          let* () = wrap_ok (State.enqueue state (Event.AreaQuery { user_id = character.user_id; area_id })) in
          
          Lwt_result.return ()