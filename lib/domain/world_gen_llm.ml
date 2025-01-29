let system_prompt = "You are a world builder for a dark fantasy MUD (Multi-User Dungeon)."
let user_prompt = "Generate a new area at (2,0,0) that connects logically with these existing areas."

let generate_chunk height width _location_id =
  Stdio.print_endline (Printf.sprintf "Generating chunk at (%d, %d, 0)" height width);
  Lwt.return_unit

let generate_world _state client ~location_id:_ =
  let%lwt () = Client_handler.send_success client "Generating world" in
  Lwt.return_unit