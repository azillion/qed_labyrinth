open Base
open Error_utils

module NpcDecisionLogic : System.Tickable = struct
  let name = "NpcDecision"

  (* A simple placeholder for a real GOAP-style planner.
     In a real system, this would be much more complex. *)
  let generate_candidates (_entity_id, _state) =
    let open Schemas_generated.Ai_comms in
    let empty_args : (string * string) list = [] in
    [
      { op_name = "GoToWork"; args = empty_args; description = "Go to your workplace to craft goods." };
      { op_name = "AcquireMaterials"; args = empty_args; description = "Go to a source of materials to restock." };
      { op_name = "Idle"; args = empty_args; description = "Do nothing and wait for something to happen." }
    ]

  let execute state =
    let open Lwt_result.Syntax in
    let* all_archetype_npcs = wrap_val (Ecs.ArchetypeStorage.all ()) in

    let rec process = function
    | [] -> Lwt_result.return ()
    | (entity_id, (arch_comp:Components.ArchetypeComponent.t)) :: rest ->
      let* goal_comp_opt = wrap_val (Ecs.GoalStorage.get entity_id) in
      match goal_comp_opt with
      | Some goal when not (String.equal goal.active_goal "Idle") ->
          (* NPC is already busy with a goal, do nothing. *)
          process rest
      | _ ->
          (* Time to make a decision. *)
          let* archetype_opt = Archetype.find_by_id arch_comp.archetype_id in
          let* behavior_opt = wrap_val (Ecs.BehaviorStorage.get entity_id) in
          let* inventory_opt = wrap_val (Ecs.InventoryStorage.get entity_id) in
          
          (* Build the request for the AI service *)
          (match archetype_opt, behavior_opt with
          | Some archetype, Some behavior ->
              let candidates = generate_candidates (entity_id, state) in
              let decision_prompt = Yojson.Safe.Util.(archetype.prompts |> member "decision_tiebreaker" |> to_string) in

              let item_comps_lwt = Lwt_list.filter_map_p (fun item_eid -> Ecs.ItemStorage.get (Uuidm.of_string item_eid |> Option.value_exn)) (Option.value_map inventory_opt ~default:[] ~f:(fun i -> i.items)) in
              let* item_comps = wrap_val item_comps_lwt in
              let item_def_ids = List.map item_comps ~f:(fun comp -> comp.item_definition_id) in
              let* pairs = Item_definition.find_names_by_ids item_def_ids in
              let inventory_summary_map =
                List.map pairs ~f:(fun (_, name) -> (name, 1l))
                |> Map.of_alist_reduce (module String) ~f:(Int32.(+))
              in
              let inventory_summary = Map.to_alist inventory_summary_map in
              
              let _ = Schemas_generated.Ai_comms.{
                npc_id = Uuidm.to_string entity_id;
                archetype_id = arch_comp.archetype_id;
                traits = behavior.traits;
                inventory = inventory_summary;
                candidates;
                decision_prompt;
              } in

              (* TODO: This will be a network call to the Python service.
                 For now, we will just log it and pick a default action. *)
              let* () = wrap_ok (Infra.Monitoring.Log.info "TODO: Call AI service with request" ~data:[("npc_id", Uuidm.to_string entity_id)] ()) in

              (* Placeholder logic: just set goal to the first candidate *)
              let chosen_op = List.hd_exn candidates in
              let new_goal = Components.GoalComponent.{
                entity_id = Uuidm.to_string entity_id;
                active_goal = chosen_op.op_name;
                context = `Assoc ["rationale", `String "Placeholder action"]
              } in
              let* () = wrap_ok (Ecs.GoalStorage.set entity_id new_goal) in
              process rest
          | _ -> process rest) (* Missing components, skip *)
    in
    let* () = process all_archetype_npcs in
    Lwt_result.return ()
end

module NpcDecision = System.MakeTickable(NpcDecisionLogic)


