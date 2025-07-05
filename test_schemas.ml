open Schemas_generated.Input

let test_direction () =
  let dir = North in
  Printf.printf "Direction: %s\n" (match dir with
    | North -> "North"
    | South -> "South"
    | East -> "East"
    | West -> "West"
    | Up -> "Up"
    | Down -> "Down"
    | Unspecified -> "Unspecified")

let test_move_command () =
  let cmd = { direction = North } in
  Printf.printf "Move command direction: %s\n" (match cmd.direction with
    | North -> "North"
    | _ -> "Other")

let test_input_event () =
  let event = {
    user_id = "user123";
    trace_id = "trace456";
    payload = Some (Move { direction = North });
  } in
  Printf.printf "Input event user_id: %s\n" event.user_id

let () =
  test_direction ();
  test_move_command ();
  test_input_event ()