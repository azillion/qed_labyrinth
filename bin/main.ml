open Base

let () =
  match Lwt_main.run (Db.connect ()) with
  | Error err ->
      Stdio.prerr_endline ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok db -> Server.Websocket.start db