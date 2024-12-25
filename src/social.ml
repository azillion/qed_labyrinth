(* src/social.ml *)
open Base
open Types

let process_interaction (actor : Agent.t) (target : Agent.t)
    (action : interaction) : Agent.t * Agent.t =
  match action with
  | Greet ->
      (* Simple relationship strengthening *)
      let new_rel = { trust = 0.1; debt = 0.0; loyalty = 0.1 } in
      let actor' = Agent.update_relationship actor target.id new_rel in
      let target' = Agent.update_relationship target actor.id new_rel in
      (actor', target')
  | Share mem ->
      (* Target learns the memory with slightly decreased significance *)
      let target' =
        Agent.add_memory target
          { mem with significance = mem.significance *. 0.9 }
      in
      (actor, target')
  | Help need ->
      (* Helping increases trust and creates debt *)
      let aid_strength =
        match need with
        | Hunger h -> 1.0 -. h (* More help for more hunger *)
        | Rest r -> 1.0 -. r
        | Social s -> 1.0 -. s
      in
      let update_rel rel =
        {
          rel with
          trust = Float.min 1.0 (rel.trust +. (0.1 *. aid_strength));
          debt = rel.debt -. (0.1 *. aid_strength);
        }
      in
      let existing_rel = Agent.find_relationship target actor.id in
      let new_rel =
        Option.value_map existing_rel
          ~default:{ trust = 0.1; debt = -0.1; loyalty = 0.0 }
          ~f:update_rel
      in
      let target' = Agent.update_relationship target actor.id new_rel in
      (actor, target')
  | RequestHelp need ->
      (* Similar to Help but reversed debt *)
      let urgency =
        match need with
        | Hunger h -> 1.0 -. h (* More urgent when lower *)
        | Rest r -> 1.0 -. r
        | Social s -> 1.0 -. s
      in
      let update_rel rel =
        {
          rel with
          trust = Float.min 1.0 (rel.trust +. (0.05 *. urgency));
          debt = rel.debt +. (0.1 *. urgency);
        }
      in
      let existing_rel = Agent.find_relationship actor target.id in
      let new_rel =
        Option.value_map existing_rel
          ~default:{ trust = 0.05; debt = 0.1; loyalty = 0.0 }
          ~f:update_rel
      in
      let actor' = Agent.update_relationship actor target.id new_rel in
      (actor', target)
