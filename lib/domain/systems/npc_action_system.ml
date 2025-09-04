open Base
open Error_utils

module NpcActionLogic : System.Tickable = struct
  let name = "NpcAction"

  let execute _state =
    let open Lwt_result.Syntax in
    let* all_goals = wrap_val (Ecs.GoalStorage.all ()) in
    let active_goals = List.filter all_goals ~f:(fun (_, g) -> not (String.equal g.active_goal "Idle")) in

    let rec process = function
    | [] -> Lwt_result.return ()
    | (entity_id, (goal:Components.GoalComponent.t)) :: rest ->
      (* TODO: This is where the goal would be translated into a series of Move events.
         For now, we will just log the action and reset the goal to Idle. *)
      let* () = wrap_ok (Infra.Monitoring.Log.info "Executing action" ~data:[("npc_id", Uuidm.to_string entity_id); ("action", goal.active_goal)] ()) in
      
      (* Mark goal as complete by setting it to Idle *)
      let idle_goal = { goal with active_goal = "Idle"; context = `Null } in
      let* () = wrap_ok (Ecs.GoalStorage.set entity_id idle_goal) in
      process rest
    in
    let* () = process active_goals in
    Lwt_result.return ()
end

module NpcAction = System.MakeTickable(NpcActionLogic)


