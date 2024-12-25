(* src/world.ml *)
open Base
open Types

type t = {
  rooms : Room.t list;
  agents : (agent_id * Agent.t) list;
  time : float;
}
[@@deriving sexp]

let create () = { rooms = []; agents = []; time = 0.0 }

let add_agent (world : t) (agent : Agent.t) : t =
  let agents = List.Assoc.add ~equal:String.equal world.agents agent.id agent in
  { world with agents }

let add_room (world : t) (room : Room.t) : t =
  { world with rooms = room :: world.rooms }

let get_agent (world : t) (id : agent_id) : Agent.t option =
  List.Assoc.find ~equal:String.equal world.agents id

let update_agent (world : t) (agent : Agent.t) : t =
  let agents = List.Assoc.add ~equal:String.equal world.agents agent.id agent in
  { world with agents }

let get_room_agents (world : t) (room : Room.t) : Agent.t list =
  List.filter_map room.present_agents ~f:(get_agent world)

let update_room (world : t) (room : Room.t) (delta_time : float) : t * Room.t =
  let agents = get_room_agents world room in

  (* Update all agent needs *)
  let updated_agents =
    List.map agents ~f:(fun a -> Agent.update_needs a delta_time)
  in

  (* Let each agent potentially act *)
  let after_actions =
    List.fold updated_agents ~init:updated_agents ~f:(fun acc agent ->
        match Agent.decide_action agent room with
        | None -> acc
        | Some action -> (
            (* Find first valid target *)
            match
              List.find acc ~f:(fun target ->
                  not (String.equal target.id agent.id))
            with
            | None -> acc
            | Some target ->
                let actor', target' =
                  Social.process_interaction agent target action
                in
                actor' :: target'
                :: List.filter acc ~f:(fun a ->
                       (not (String.equal a.id agent.id))
                       && not (String.equal a.id target.id))))
  in

  (* Update world state with new agent states *)
  let world' =
    List.fold after_actions ~init:world ~f:(fun acc agent ->
        update_agent acc agent)
  in

  let room' =
    { room with present_agents = List.map after_actions ~f:(fun a -> a.id) }
  in

  (world', room')
