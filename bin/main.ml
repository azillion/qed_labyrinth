(* bin/main.ml *)
open Base
open Qed_labyrinth_lib
open Stdio

(* Create initial room *)
let initial_room =
  {
    Types.Room.id = "common_room";
    name = "The Common Room";
    physical_state =
      [
        { name = "table"; state = "clean" };
        { name = "chairs"; state = "arranged" };
        { name = "window"; state = "open" };
      ];
    social_dynamics = [];
    recent_events = [];
    present_agents = [];
  }

(* Create some test agents *)
let alice = Agent.create ~id:"alice" ~name:"Alice"
let bob = Agent.create ~id:"bob" ~name:"Bob"
let charlie = Agent.create ~id:"charlie" ~name:"Charlie"

(* Helper to print agent state *)
let print_agent_state agent =
  printf "\nAgent: %s\n" agent.Agent.name;
  printf "Needs:\n";
  List.iter agent.needs ~f:(function
    | Types.Hunger h -> printf "  Hunger: %.2f\n" h
    | Rest r -> printf "  Rest: %.2f\n" r
    | Social s -> printf "  Social: %.2f\n" s);
  printf "Relationships:\n";
  List.iter agent.relationships ~f:(fun (id, rel) ->
      printf "  With %s - Trust: %.2f, Debt: %.2f, Loyalty: %.2f\n" id rel.trust
        rel.debt rel.loyalty)

(* Run simulation for n ticks *)
let run_simulation n_ticks =
  (* Initialize world *)
  let world = World.create () in
  let world = World.add_room world initial_room in
  let world = World.add_agent world alice in
  let world = World.add_agent world bob in
  let world = World.add_agent world charlie in

  (* Put agents in room *)
  let room =
    { initial_room with present_agents = [ "alice"; "bob"; "charlie" ] }
  in

  (* Run simulation *)
  let rec simulate tick (world, room) =
    if tick >= n_ticks then
      (world, room)
    else (
      printf "\n=== Tick %d ===\n" tick;

      (* Update world and print state *)
      let world', room' = World.update_room world room 0.1 in

      List.iter (World.get_room_agents world' room') ~f:print_agent_state;

      simulate (tick + 1) (world', room'))
  in

  simulate 0 (world, room)

let () =
  printf "Starting simulation...\n";
  let _final_world, _final_room = run_simulation 5 in
  printf "\nSimulation complete.\n"
