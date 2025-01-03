(* test_event.ml *)
let test_event_serialization () =
  let event =
    Event.player_moved ~from_space_id:"kitchen" ~to_space_id:"garden"
      ~direction:"east"
  in
  let json = Event.to_yojson event in
  match Event.of_yojson json with
  | Ok decoded -> assert (Event.get_id event = Event.get_id decoded)
  | Error msg -> failwith msg

(* test_state.ml *)
let test_state_rebuild () =
  let events =
    [
      Event.player_moved ~from_space_id:"start" ~to_space_id:"kitchen"
        ~direction:"north";
      Event.player_looked ~space_id:"kitchen";
      Event.player_moved ~from_space_id:"kitchen" ~to_space_id:"garden"
        ~direction:"east";
    ]
  in
  let final_state = State.rebuild_from_events events in
  assert (final_state.current_space_id = "garden")
