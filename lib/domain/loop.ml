open Lwt.Syntax

let tick (state : State.t) =
  let delta = Unix.gettimeofday () -. state.last_tick in
  let* () = Lwt_unix.sleep (Float.max 0.0 (0.01 -. delta)) in
  State.update_tick state;
  (* ignore (Stdio.print_endline (Printf.sprintf "Tick: %f" delta)); *)
  Lwt.return_unit

let process_client_messages (state : State.t) =
  let rec process_all () =
    match%lwt Infra.Queue.pop_opt state.client_message_queue with
    | None -> Lwt.return_unit
    | Some { message; client } ->
        let* () =
          Lwt_list.iter_s
            (fun (module H : Client_handler.S) -> H.handle state client message)
            Handlers.all_client_handlers
        in
        process_all ()
  in

  Lwt.catch
    (fun () -> process_all ())
    (fun exn ->
      Stdio.eprintf "Message processing error: %s\n" (Base.Exn.to_string exn);
      Lwt.return_unit)

let process_events (state : State.t) =
  let rec process_all () =
    match%lwt Infra.Queue.pop_opt state.event_queue with
    | None -> Lwt.return_unit
    | Some _event ->
        (* let* () = process_event state event in *)
        process_all ()
  in
  Lwt.catch
    (fun () -> process_all ())
    (fun exn ->
      Stdio.eprintf "Event processing error: %s\n" (Base.Exn.to_string exn);
      Lwt.return_unit)

let register_ecs_systems (_state : State.t) =
  (* Register your ECS systems here *)
  (* For example: State.register_system state my_system *)
  Lwt.return_unit

let rec game_loop (state : State.t) =
  Lwt.catch
    (fun () ->
      let* () = tick state in
      let* () = process_client_messages state in
      game_loop state)
    (fun exn ->
      Stdio.eprintf "Game loop error: %s\n" (Base.Exn.to_string exn);
      game_loop state)

let run (state : State.t) =
  let* () = register_ecs_systems state in
  game_loop state
