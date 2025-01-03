open Core

(* we should load the store if the file exists *)
let event_store =
  try ref (EventStore.load "game_events.json")
  with _ -> ref (EventStore.create "game_events.json")

type command = Look | Move of string | Quit | Unknown

let valid_directions = [ "north"; "south"; "east"; "west" ]

let parse_command input =
  match
    String.trim input |> String.lowercase_ascii |> String.split_on_char ' '
  with
  | [ "look" ] -> Look
  | [ "move"; direction ] when List.mem direction valid_directions ->
      Move direction
  | [ "move"; _ ] ->
      Printf.printf "\nInvalid direction. Use: north, south, east, or west\n";
      Unknown
  | [ "quit" ] -> Quit
  | _ ->
      Printf.printf "\nValid commands are: look, move <direction>, quit\n";
      Unknown

let find_connection direction space =
  List.find_opt
    (fun conn -> String.equal conn.Space.direction direction)
    space.Space.connections

let handle_look state spaces =
  let space =
    List.find
      (fun s -> String.equal s.Space.id state.State.current_space_id)
      spaces
  in
  let exits = List.map (fun c -> c.Space.direction) space.Space.connections in
  let exits_str =
    match exits with [] -> "none" | es -> String.concat ", " es
  in
  Printf.printf "\n%s\n%s\nExits: %s\n" space.Space.name space.Space.description
    exits_str;
  let event = Event.player_looked ~space_id:state.State.current_space_id in
  event_store := EventStore.append !event_store event;
  { state with event_log = event :: state.event_log }

let handle_move direction state spaces =
  let current_space =
    List.find
      (fun s -> String.equal s.Space.id state.State.current_space_id)
      spaces
  in
  match find_connection direction current_space with
  | None ->
      Printf.printf "\nYou can't go %s from here.\n" direction;
      state
  | Some connection ->
      let event =
        Event.player_moved ~from_space_id:state.State.current_space_id
          ~to_space_id:connection.target ~direction
      in
      event_store := EventStore.append !event_store event;
      let new_state =
        {
          State.current_space_id = connection.target;
          event_log = event :: state.State.event_log;
        }
      in
      handle_look new_state spaces

let game_loop initial_state spaces =
  let rec loop state =
    Printf.printf "\n> ";
    match read_line () with
    | exception End_of_file -> state
    | input -> (
        match parse_command input with
        | Look ->
            let new_state = handle_look state spaces in
            loop new_state
        | Move direction ->
            let new_state = handle_move direction state spaces in
            loop new_state
        | Quit ->
            Printf.printf "\nGoodbye!\n";
            state
        | Unknown ->
            Printf.printf "\nI don't understand that command.\n";
            loop state)
  in
  loop initial_state

let start_game starting_space_id spaces =
  let stored_events = EventStore.get_events !event_store in
  Printf.printf "Loaded %d events\n" (List.length stored_events);

  let initial_state =
    match stored_events with
    | [] -> State.create starting_space_id
    | _ ->
        let state = State.rebuild_from_events stored_events in
        Printf.printf "Reconstructed state space: %s\n" state.current_space_id;
        state
  in

  let final_state = game_loop initial_state spaces in
  final_state
