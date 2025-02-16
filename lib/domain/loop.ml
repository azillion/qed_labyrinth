open Lwt.Syntax

let process_client_messages ?(timeout_seconds = 1.0) (state : State.t) =
  let rec process_all () =
    match%lwt Queue.pop_opt state.message_queue with
    | None -> Lwt.return_unit
    | Some { message; client } ->
        let process_promise =
          let* () =
            Lwt_list.iter_s
              (fun (module H : Client_handler.S) -> H.handle state client message)
              Handlers.all_client_handlers
          in
          process_all ()
        in
        let timeout =
          let* () = Lwt_unix.sleep timeout_seconds in
          Stdio.eprintf "Message processing timeout after %f seconds\n" timeout_seconds;
          Lwt.return_unit
        in
        Lwt.pick [process_promise; timeout]

  in
  Lwt.catch
    (fun () -> process_all ())
    (fun exn ->
      Stdio.eprintf "Message processing error: %s\n" (Base.Exn.to_string exn);
      Lwt.return_unit)

let tick (state : State.t) =
  let delta = Unix.gettimeofday () -. state.last_tick in
  let* () = Lwt_unix.sleep (Float.max 0.0 (0.01 -. delta)) in
  State.update_tick state;
  (* ignore (Stdio.print_endline (Printf.sprintf "Tick: %f" delta)); *)
  Lwt.return_unit

let rec run (state : State.t) =
  Lwt.catch
    (fun () ->
      let* () = tick state in
      let* () = process_client_messages state in
      run state)
    (fun exn ->
      Stdio.eprintf "Game loop error: %s\n" (Base.Exn.to_string exn);
      run state)
