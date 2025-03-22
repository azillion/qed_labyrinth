open Lwt.Syntax
open Event

let tick (state : State.t) =
  let delta = Unix.gettimeofday () -. state.last_tick in
  let* () = Lwt_unix.sleep (Float.max 0.0 (0.01 -. delta)) in
  State.update_tick state;
  (* let* () = Lwt_io.printl (Printf.sprintf "Tick: %f" delta) in *)
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
      let* () = Lwt_io.printl (Printf.sprintf "Message processing error: %s" (Base.Exn.to_string exn)) in
      Lwt.return_unit)

(* Process events from the queue *)
let process_events (state : State.t) =
  let rec process_all () =
    match%lwt Infra.Queue.pop_opt state.event_queue with
    | None -> Lwt.return_unit
    | Some event ->
        match event with
        | CharacterListRequested { user_id } ->
            let%lwt () = Character_system.Character_list_system.handle_character_list_requested state user_id in
            process_all ()
        | CreateCharacter { user_id; name; description; starting_area_id } ->
            let%lwt () = Character_system.Character_creation_system.handle_create_character state user_id name description starting_area_id in
            process_all ()
        | _ -> process_all ()
  in
  Lwt.catch
    (fun () -> process_all ())
    (fun exn ->
      let* () = Lwt_io.printl (Printf.sprintf "Event processing error: %s" (Base.Exn.to_string exn)) in
      Lwt.return_unit)

let register_ecs_systems (_state : State.t) =
  (* Register your ECS systems here *)
  (* Ecs.World.register_system Character_system.Character_list_system.execute
    ~priority:Character_system.Character_list_system.priority; *)
  Lwt.return_unit

let rec game_loop (state : State.t) =
  Lwt.catch
    (fun () ->
      let* () = Lwt_io.flush Lwt_io.stdout in
      let* () = tick state in
      let* () = process_client_messages state in
      let* () = process_events state in
      let* () = Ecs.World.step () in
      game_loop state)
    (fun exn ->
      let* () = Lwt_io.printl (Printf.sprintf "Game loop error: %s" (Base.Exn.to_string exn)) in
      game_loop state)

let run (state : State.t) =
  let* init_result = Ecs.World.init () in
  match init_result with
  | Ok () ->
      let* () = register_ecs_systems state in
      game_loop state
  | Error e ->
      let* () = Lwt_io.printl (Printf.sprintf "World initialization error: %s" (Base.Error.to_string_hum e)) in
      Lwt.return_unit
