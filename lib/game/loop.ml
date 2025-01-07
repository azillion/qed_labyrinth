open Base

let tick state =
  let now = Unix.gettimeofday () in
  let delta = now -. state.State.last_tick in

  (* Update game systems *)
  let%lwt () = Lwt_unix.sleep (Float.max 0.0 (1.0 -. delta)) in
  State.update_tick state;
  Lwt.return_unit

let rec run state =
  Lwt.catch
    (fun () ->
      let%lwt () = tick state in
      run state)
    (fun exn ->
      Stdio.eprintf "Game loop error: %s\n" (Exn.to_string exn);
      run state)
