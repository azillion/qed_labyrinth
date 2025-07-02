open Lwt.Syntax
open Base

module Queue = Infra.Queue

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

(* Add this new helper function first *)
let process_event (state : State.t) (event : Event.t) =
  match event with
  | Event.CharacterListRequested { user_id } ->
      Character_system.Character_list_system.handle_character_list_requested state user_id
  | Event.CreateCharacter { user_id; name; description; starting_area_id } ->
      Character_system.Character_creation_system.handle_create_character state user_id name description starting_area_id
  | Event.CharacterSelected { user_id; character_id } ->
      Character_system.Character_selection_system.handle_character_selected state user_id character_id
  
  | Event.SendCharacterList { user_id; characters } ->
      Character_system.Character_list_communication_system.handle_character_list state user_id characters |> Lwt_result.ok
  | Event.SendCharacterCreated { user_id; character } ->
      Character_system.Character_creation_communication_system.handle_character_created state user_id character |> Lwt_result.ok
  | Event.SendCharacterCreationFailed { user_id; error } ->
      Character_system.Character_creation_communication_system.handle_character_creation_failed state user_id error |> Lwt_result.ok
  | Event.SendCharacterSelected { user_id; character } ->
      Character_system.Character_selection_communication_system.handle_character_selected state user_id character |> Lwt_result.ok
  | Event.SendCharacterSelectionFailed { user_id; error } ->
      Character_system.Character_selection_communication_system.handle_character_selection_failed state user_id error |> Lwt_result.ok
  
  | Event.AreaQuery { user_id; area_id } ->
      Area_management_system.Area_query_system.handle_area_query state user_id area_id |> Lwt_result.ok
  | Event.AreaQueryResult { user_id; area } ->
      Area_management_system.Area_query_communication_system.handle_area_query_result state user_id area |> Lwt_result.ok
  
  | Event.Move { user_id; direction } ->
      Movement_system.System.handle_move state user_id direction
  | Event.PlayerMoved { user_id; old_area_id; new_area_id; direction } ->
      Presence_system.System.handle_player_moved state user_id old_area_id new_area_id direction
  | Event.SendMovementFailed { user_id; reason } ->
      (* This is a communication event, so it's okay to just send *)
      (match Connection_manager.find_client_by_user_id state.connection_manager user_id with
      | Some client -> client.send (Protocol.CommandFailed { error = reason }) |> Lwt_result.ok
      | None -> Lwt_result.return ())
  
  | Event.Say { user_id; content } ->
      Communication_system.System.handle_say state user_id content
  | Event.Announce { area_id; message } ->
      Communication_system.System.handle_announce state area_id message
  | Event.Tell { user_id; message } ->
      Communication_system.System.handle_tell state user_id message
  | Event.RequestChatHistory { user_id; area_id } ->
      Communication_system.Chat_history_system.handle_request_chat_history state user_id area_id
  | Event.SendChatHistory { user_id; messages } ->
      Communication_system.Chat_history_system.handle_send_chat_history state user_id messages
  | Event.UpdateAreaPresence { area_id; characters } ->
      (* For now, just log this event - we can implement full presence updates later *)
      let%lwt () = Lwt_io.printl (Printf.sprintf "Area presence update for %s: %d characters" area_id (List.length characters)) in
      Lwt_result.return ()
  
  (* Add other event handlers here as they are refactored *)
  | _ -> Lwt_result.return () (* Ignore unhandled events for now *)

(* Replace the old process_events with this new one *)
let process_events (state : State.t) =
  let rec process_all () =
    match%lwt Infra.Queue.pop_opt state.event_queue with
    | None -> Lwt.return_unit
    | Some event ->
        let%lwt result = process_event state event in
        let%lwt () = match result with
        | Ok () -> Lwt.return_unit (* Success, continue *)
        | Error err ->
            let err_str = Qed_error.to_string err in
            Stdio.printf "[EVENT_ERROR] %s\n" err_str;
            (* Queue appropriate failure events based on the original event type *)
            (match event with
            | Event.CreateCharacter { user_id; _ } ->
                Infra.Queue.push state.event_queue (
                  Event.SendCharacterCreationFailed { 
                    user_id; 
                    error = Qed_error.to_yojson err 
                  }
                )
            | Event.CharacterSelected { user_id; _ } ->
                Infra.Queue.push state.event_queue (
                  Event.SendCharacterSelectionFailed { 
                    user_id; 
                    error = Qed_error.to_yojson err 
                  }
                )
            | Event.CharacterListRequested { user_id } ->
                Infra.Queue.push state.event_queue (
                  Event.SendCharacterList { user_id; characters = [] }
                )
            | _ -> (* For other events, just log the error *)
                Lwt.return_unit)
        in
        process_all ()
  in
  process_all ()

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
