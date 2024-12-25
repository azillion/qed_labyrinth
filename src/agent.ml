(* src/agent.ml *)
open Base
open Types

type t = {
  id : agent_id;
  name : string;
  needs : need list;
  memories : memory list;
  relationships : (agent_id * relationship) list;
  status : float; (* social standing, 0.0 to 1.0 *)
}
[@@deriving sexp, compare]

let create ~id ~name =
  {
    id;
    name;
    needs = [ Hunger 1.0; Rest 1.0; Social 1.0 ];
    memories = [];
    relationships = [];
    status = 0.5;
  }

let update_need (n : need) (delta : float) : need =
  match n with
  | Hunger h -> Hunger (Float.max 0.0 (Float.min 1.0 (h +. delta)))
  | Rest r -> Rest (Float.max 0.0 (Float.min 1.0 (r +. delta)))
  | Social s -> Social (Float.max 0.0 (Float.min 1.0 (s +. delta)))

let update_needs (agent : t) (delta_time : float) : t =
  let update_needs =
    List.map ~f:(fun n -> update_need n (delta_time *. -0.1)) agent.needs
  in
  { agent with needs = update_needs }

let add_memory (agent : t) (mem : memory) : t =
  let sorted_memories =
    mem :: agent.memories
    |> List.sort ~compare:(fun m1 m2 ->
           Float.compare m2.significance m1.significance)
    |> fun l -> List.take l 100
    (* Keep only most significant memories *)
  in
  { agent with memories = sorted_memories }

let find_relationship (agent : t) (target_id : agent_id) : relationship option =
  List.Assoc.find ~equal:String.equal agent.relationships target_id

let update_relationship (agent : t) (target_id : agent_id) (rel : relationship)
    : t =
  let relationships =
    List.Assoc.add ~equal:String.equal agent.relationships target_id rel
  in
  { agent with relationships }

let decide_action (agent : t) (room : Room.t) : interaction option =
  (* Only consider acting if other agents are present *)
  let other_agents =
    List.filter room.present_agents ~f:(fun id ->
        not (String.equal id agent.id))
  in
  if List.is_empty other_agents then
    None
  else
    (* Find most pressing need *)
    let urgent_need =
      List.find
        ~f:(function
          | Hunger h -> Float.(h < 0.3)
          | Rest r -> Float.(r < 0.3)
          | Social s -> Float.(s < 0.3))
        agent.needs
    in
    match urgent_need with
    | Some need -> Some (RequestHelp need)
    | None -> (
        (* If no urgent needs, maybe share a significant memory *)
        match agent.memories with
        | m :: _ ->
            if Float.(m.significance > 0.7) then
              Some (Share m)
            else
              None
        | _ -> None)
