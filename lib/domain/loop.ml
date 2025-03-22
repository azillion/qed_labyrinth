open Lwt.Syntax
open Base

module Queue = Infra.Queue
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
            let* () = Lwt.catch
              (fun () -> Character_system.Character_list_system.handle_character_list_requested state user_id)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Character list error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | CreateCharacter { user_id; name; description; starting_area_id } ->
            let* () = Lwt.catch
              (fun () -> Character_system.Character_creation_system.handle_create_character state user_id name description starting_area_id)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Character creation error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | CharacterSelected { user_id; character_id } ->
            let* () = Lwt.catch
              (fun () -> Character_system.Character_selection_system.handle_character_selected state user_id character_id)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Character selection error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        
        (* Communication events handlers *)
        | SendCharacterList { user_id; characters } ->
            let* () = Lwt.catch
              (fun () -> Character_system.Character_list_communication_system.handle_character_list state user_id characters)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Sending character list error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | SendCharacterCreated { user_id; character } ->
            let* () = Lwt.catch
              (fun () -> Character_system.Character_creation_communication_system.handle_character_created state user_id character)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Sending character created error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | SendCharacterCreationFailed { user_id; error } ->
            let* () = Lwt.catch
              (fun () -> Character_system.Character_creation_communication_system.handle_character_creation_failed state user_id error)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Sending character creation failed error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | SendCharacterSelected { user_id; character } ->
            let* () = Lwt.catch
              (fun () -> Character_system.Character_selection_communication_system.handle_character_selected state user_id character)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Sending character selected error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | SendCharacterSelectionFailed { user_id; error } ->
            let* () = Lwt.catch
              (fun () -> Character_system.Character_selection_communication_system.handle_character_selection_failed state user_id error)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Sending character selection failed error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
            
            
        (* Area management events *)
        | CreateArea { user_id; name; description; x; y; z; elevation; temperature; moisture } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Area_creation_system.handle_create_area 
                state user_id name description x y z ?elevation ?temperature ?moisture ())
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Area creation error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | CreateExit { user_id; from_area_id; to_area_id; direction; description; hidden; locked } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Exit_creation_system.handle_create_exit 
                state user_id from_area_id to_area_id direction description hidden locked)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Exit creation error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | AreaQuery { user_id; area_id } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Area_query_system.handle_area_query state user_id area_id)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Area query error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
            
        (* Area management communication events *)
        | AreaCreated { user_id; area_id } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Area_creation_communication_system.handle_area_created state user_id area_id)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Area created communication error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | AreaCreationFailed { user_id; error } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Area_creation_communication_system.handle_area_creation_failed state user_id error)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Area creation failed communication error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | ExitCreated { user_id; exit_id } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Exit_creation_communication_system.handle_exit_created state user_id exit_id)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Exit created communication error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | ExitCreationFailed { user_id; error } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Exit_creation_communication_system.handle_exit_creation_failed state user_id error)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Exit creation failed communication error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | AreaQueryResult { user_id; area } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Area_query_communication_system.handle_area_query_result state user_id area)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Area query result communication error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        | AreaQueryFailed { user_id; error } ->
            let* () = Lwt.catch
              (fun () -> Area_management_system.Area_query_communication_system.handle_area_query_failed state user_id error)
              (fun exn ->
                let* () = Lwt_io.printl (Printf.sprintf "Area query failed communication error for user %s: %s" user_id (Base.Exn.to_string exn)) in
                Lwt.return_unit) in
            process_all ()
        
        | _ -> process_all ()
  in
  Lwt.catch
    (fun () -> process_all ())
    (fun exn ->
      if String.equal (Base.Exn.to_string exn) "End_of_file" then
        let* () = Lwt_io.printl "Event processing error: End_of_file - Database connection may have been closed" in
        Lwt.return_unit
      else
        let* () = Lwt_io.printl (Printf.sprintf "Event processing error: %s" (Base.Exn.to_string exn)) in
        Lwt.return_unit)

let register_ecs_systems (_state : State.t) =
  (* Register your ECS systems here *)
  
  Initialization_system.Starting_area_initialization_system.initialize_starting_area_once ();
  
  Lwt.return_unit

let rec game_loop (state : State.t) =
  Lwt.catch
    (fun () ->
      let* () = Lwt_io.flush Lwt_io.stdout in
      let* () = tick state in
      let* () = process_client_messages state in
      let* () = process_events state in
      let* () = Ecs.World.step () in
      
      let* () = 
        Lwt.catch
          (fun () -> Ecs.World.sync_to_db ())
          (fun exn ->
            let* () = Lwt_io.printl (Printf.sprintf "Database sync error in game loop: %s" (Base.Exn.to_string exn)) in
            Lwt.return_unit) in

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
