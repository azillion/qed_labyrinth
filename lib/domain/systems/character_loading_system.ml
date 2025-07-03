open Qed_error

let handle_load_character state character_id =
  let open Lwt_result.Syntax in
  (* Call Character.find_by_id to get relational data from Tier 1 *)
  let* character_opt = Character.find_by_id character_id in
  match character_opt with
  | None ->
      Lwt_result.fail (CharacterNotFound)
  | Some character ->
      (* Convert character_id string to Uuidm.t entity ID *)
      match Uuidm.of_string character_id with
      | None ->
          Lwt_result.fail (InvalidCharacter)
      | Some entity_id ->
          (* Create CoreStatsComponent from character.core_stats *)
          let core_stats_component = Components.CoreStatsComponent.{
            entity_id = character_id;
            might = character.core_stats.might;
            finesse = character.core_stats.finesse;
            wits = character.core_stats.wits;
            grit = character.core_stats.grit;
            presence = character.core_stats.presence;
          } in
          let* () = Ecs.CoreStatsStorage.set entity_id core_stats_component |> Lwt_result.ok in
          
          (* Load or create CharacterPositionComponent *)
          let* pos_opt = Ecs.CharacterPositionStorage.get entity_id |> Lwt_result.ok in
          let* () = match pos_opt with
            | Some _ -> Lwt_result.return () (* Position already exists *)
            | None ->
                (* Create new position pointing to default starting area *)
                let position_component = Components.CharacterPositionComponent.{
                  entity_id = character_id;
                  area_id = "00000000-0000-0000-0000-000000000000";
                } in
                Ecs.CharacterPositionStorage.set entity_id position_component |> Lwt_result.ok
          in
          
          (* Call calculate_and_update_stats to compute derived stats *)
          let* () = Character_stat_system.calculate_and_update_stats entity_id in
          
          (* Construct Types.character record from loaded components *)
          let* health_opt = Ecs.HealthStorage.get entity_id |> Lwt_result.ok in
          let* action_points_opt = Ecs.ActionPointsStorage.get entity_id |> Lwt_result.ok in
          let* position_opt = Ecs.CharacterPositionStorage.get entity_id |> Lwt_result.ok in
          
          let _location_id = match position_opt with
            | Some pos -> pos.area_id
            | None -> "00000000-0000-0000-0000-000000000000"
          in
          
          let (health, max_health) = match health_opt with
            | Some h -> (h.current, h.max)
            | None -> (100, 100) (* Fallback values *)
          in
          
          let (mana, max_mana) = match action_points_opt with
            | Some ap -> (ap.current, ap.max)
            | None -> (100, 100) (* Fallback values *)
          in
          
          (* Get character name from DescriptionComponent *)
          let* desc_opt = Ecs.DescriptionStorage.get entity_id |> Lwt_result.ok in
          let character_name = match desc_opt with
            | Some desc -> desc.Components.DescriptionComponent.name
            | None -> character.name (* Fallback to character.name *)
          in
          
          (* Get core attributes from CoreStatsComponent *)
          let* core_stats_opt = Ecs.CoreStatsStorage.get entity_id |> Lwt_result.ok in
          let core_attributes = match core_stats_opt with
            | Some cs -> Types.{
                might = cs.Components.CoreStatsComponent.might;
                finesse = cs.finesse;
                wits = cs.wits;
                grit = cs.grit;
                presence = cs.presence;
              }
            | None -> Types.{ might = 5; finesse = 5; wits = 5; grit = 5; presence = 5 } (* Fallback *)
          in
          
          (* Get derived stats from DerivedStatsComponent *)
          let* derived_stats_opt = Ecs.DerivedStatsStorage.get entity_id |> Lwt_result.ok in
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
            action_points = mana; (* Using mana as action_points for now *)
            max_action_points = max_mana;
            core_attributes;
            derived_stats;
          } in
          
          (* Queue SendCharacterSelected event *)
          let* () = Infra.Queue.push state.State.event_queue (
            Event.SendCharacterSelected { user_id = character.user_id; character_sheet }
          ) |> Lwt_result.ok in
          
          Lwt_result.return ()