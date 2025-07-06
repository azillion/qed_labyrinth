open Base
open Infra
open Redis_lwt

let () =
  let config = Config.Database.from_env () in
  match Lwt_main.run (Database.Pool.connect config) with
  | Error err ->
      Stdio.prerr_endline
        ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok () -> 
      let redis = Client.create () in
      let app_state = Qed_domain.State.create redis in
      Stdio.print_endline "Database connected successfully";
      Lwt_main.run (Qed_domain.Loop.run app_state)
