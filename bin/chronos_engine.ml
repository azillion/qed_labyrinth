open Base
open Infra

let () =
  let config = Config.Database.from_env () in
  match Lwt_main.run (Database.Pool.connect config) with
  | Error err ->
      Stdio.prerr_endline
        ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok () -> 
      Stdio.print_endline "Database connected successfully";
      Lwt_main.run (
        let open Lwt.Syntax in
        let redis_host = Stdlib.Sys.getenv_opt "REDIS_HOST" |> Option.value ~default:"127.0.0.1" in
        let redis_port = 
          match Stdlib.Sys.getenv_opt "REDIS_PORT" with
          | None -> 6379
          | Some port_str -> 
              try Int.of_string port_str with _ -> 6379 
        in
        let* redis = Redis_lwt.Client.connect { host = redis_host; port = redis_port } in
        let app_state = Qed_domain.State.create redis in
        Qed_domain.Loop.run app_state
      )
