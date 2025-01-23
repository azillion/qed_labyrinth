open Lwt.Syntax

let state = State.create ()

let tick =
  let* _msg = Queue.pop state.message_queue in
  (* Handle message *)
  let delta = Unix.gettimeofday () -. state.last_tick in
  let* () = Lwt_unix.sleep (Float.max 0.0 (0.1 -. delta)) in
  State.update_tick state; 
  (* ignore (Stdio.print_endline (Printf.sprintf "Tick: %f" delta)); *)
  Lwt.return_unit

let rec run () =
  Lwt.catch
    (fun () ->
      let%lwt () = tick in
      run ())
    (fun exn ->
      Stdio.eprintf "Game loop error: %s\n" (Base.Exn.to_string exn);
      run ())
