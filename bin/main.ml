open Base
open Infra

let () =
  let config = Config.Database.from_env () in
  match Lwt_main.run (Database.Pool.connect config) with
  | Error err ->
      Stdio.prerr_endline
        ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok () -> Lwt_main.run (Server.start ())
