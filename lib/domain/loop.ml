open Lwt.Syntax
open Base

module Queue = Infra.Queue

(* Helper function to convert protobuf directions to internal directions *)
let direction_of_proto (proto_direction : Schemas_generated.Input.direction) =
  match proto_direction with
  | Schemas_generated.Input.North -> Components.ExitComponent.North
  | Schemas_generated.Input.South -> Components.ExitComponent.South
  | Schemas_generated.Input.East -> Components.ExitComponent.East
  | Schemas_generated.Input.West -> Components.ExitComponent.West
  | Schemas_generated.Input.Up -> Components.ExitComponent.Up
  | Schemas_generated.Input.Down -> Components.ExitComponent.Down
  | Schemas_generated.Input.Unspecified -> failwith "Unspecified direction"

(* Main conversion function from protobuf to internal events *)
let event_of_protobuf (proto_event : Schemas_generated.Input.input_event) =
  match proto_event.payload with
  | None -> None
  | Some payload ->
      match payload with
      | Move move_cmd ->
          let direction = direction_of_proto move_cmd.direction in
          Some (Event.Move { user_id = proto_event.user_id; direction })
      | Say say_cmd ->
          Some (Event.Say { user_id = proto_event.user_id; content = say_cmd.content })

(* Redis subscriber function *)
let subscribe_to_player_commands (state : State.t) =
  let open Lwt.Syntax in
  (* Subscribe to the player_commands channel *)
  let* () = Redis_lwt.Client.subscribe state.redis_conn ["player_commands"] in
  (* Get the reply stream from the connection *)
  let reply_stream = Redis_lwt.Client.stream state.redis_conn in
  (* Process incoming messages *)
  Lwt_stream.iter_s (fun replies ->
    let* () = Lwt_list.iter_s (fun reply ->
      match reply with
      | `Multibulk [`Bulk (Some "message"); `Bulk (Some _channel); `Bulk (Some message_content)] ->
          (* This is a pub/sub message *)
          (try
            let proto_event = Schemas_generated.Input.decode_pb_input_event (Pbrt.Decoder.of_string message_content) in
            match event_of_protobuf proto_event with
            | Some event -> 
                Infra.Queue.push state.event_queue event
            | None -> 
                Stdio.eprintf "Failed to convert protobuf message to event\n";
                Lwt.return_unit
          with
          | exn ->
              Stdio.eprintf "Error processing Redis message: %s\n" (Base.Exn.to_string exn);
              Lwt.return_unit)
      | _ -> 
          (* Ignore other reply types (like subscription confirmations) *)
          Lwt.return_unit
    ) replies in
    Lwt.return_unit
  ) reply_stream

(* Helper function to publish events to Redis *)
(* publish_event and publish_system_message_to_user moved to Publisher module *)

let tick (state : State.t) =
  let delta = Unix.gettimeofday () -. state.last_tick in
  let* () = Lwt_unix.sleep (Float.max 0.0 (0.01 -. delta)) in
  State.update_tick state;
  (* let* () = Lwt_io.printl (Printf.sprintf "Tick: %f" delta) in *)
  Lwt.return_unit


(* Add this new helper function first *)
let process_event (state : State.t) (event : Event.t) =
  match event with
  | Event.CharacterListRequested { user_id } ->
      Character_system.Character_list_system.handle_character_list_requested state user_id
  | Event.CreateCharacter { user_id; name; description; starting_area_id; might; finesse; wits; grit; presence } ->
      Character_system.Character_creation_system.handle_create_character state user_id name description starting_area_id might finesse wits grit presence
  | Event.CharacterSelected { user_id; character_id } ->
      Character_system.Character_selection_system.handle_character_selected state user_id character_id
  | Event.LoadCharacterIntoECS { user_id = _; character_id } ->
      Character_loading_system.handle_load_character state character_id
  | Event.UnloadCharacterFromECS { user_id; character_id } ->
      Character_unloading_system.handle_unload_character state user_id character_id
  
  | Event.SendCharacterList { user_id = _; characters = _ } ->
      (* Character list is now handled by the API server via Redis events *)
      Lwt_result.return ()
  | Event.SendCharacterCreated { user_id = _; character = _ } ->
      (* Character creation response is now handled by the API server via Redis events *)
      Lwt_result.return ()
  | Event.SendCharacterCreationFailed { user_id = _; error = _ } ->
      (* Character creation failure response is now handled by the API server via Redis events *)
      Lwt_result.return ()
  | Event.SendCharacterSelected { user_id = _; character_sheet = _ } ->
      (* Character selection response is now handled by the API server via Redis events *)
      Lwt_result.return ()
  | Event.SendCharacterSelectionFailed { user_id = _; error = _ } ->
      (* Character selection failure response is now handled by the API server via Redis events *)
      Lwt_result.return ()
  
  | Event.AreaQuery { user_id; area_id } ->
      Area_management_system.Area_query_system.handle_area_query state user_id area_id |> Lwt_result.ok
  | Event.AreaQueryResult { user_id; area } ->
      Area_management_system.Area_query_communication_system.handle_area_query_result state user_id area |> Lwt_result.ok
  
  | Event.Move { user_id; direction } ->
      Movement_system.System.handle_move state user_id direction
  | Event.PlayerMoved { user_id; old_area_id; new_area_id; direction } ->
      Presence_system.System.handle_player_moved state user_id old_area_id new_area_id direction
  | Event.SendMovementFailed { user_id; reason } ->
      (* Movement failure response is now handled by the API server via Redis events *)
      let* () = Publisher.publish_system_message_to_user state user_id reason in
      Lwt_result.return ()
  
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
  
  | Event.CharacterCreated { user_id; character_id } ->
      (* After a character has been created in the DB, look it up so we can notify the
         client and continue the workflow. We transform the DB record into a
         Types.list_character payload and enqueue a SendCharacterCreated event so
         that the communication layer can deliver it. *)
      let open Lwt_result.Syntax in
      let* character_opt = Character.find_by_id character_id in
      (match character_opt with
      | None ->
          (* This should be rare – the character was just created but we can no longer
             find it. Treat as an error and fall back to the normal error path. *)
          let* () = Infra.Queue.push state.State.event_queue (
            Event.SendCharacterCreationFailed
              { user_id; error = Qed_error.to_yojson Qed_error.CharacterNotFound }
          ) |> Lwt_result.ok in
          Lwt_result.return ()
      | Some character ->
          let list_character : Types.list_character =
            { id = character.id; name = character.name } in
          let* () = Infra.Queue.push state.State.event_queue (
            Event.SendCharacterCreated { user_id; character = list_character }
          ) |> Lwt_result.ok in
          (* Optionally, automatically load the new character into ECS so it can be
             used immediately. Comment this in for now to keep the flow simple. *)
          let* () = Infra.Queue.push state.State.event_queue (
            Event.LoadCharacterIntoECS { user_id; character_id }
          ) |> Lwt_result.ok in
          let%lwt () = Lwt_io.printl (Printf.sprintf "[EVENT] CharacterCreated processed for user=%s char_id=%s" user_id character_id) in
          Lwt_result.return ())
  
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
            let* () = Lwt_io.printl (Printf.sprintf "[EVENT_ERROR] %s" err_str) in
            (* Send appropriate failure messages directly to users *)
            (match event with
            | Event.CreateCharacter { user_id; _ } ->
                Publisher.publish_system_message_to_user state user_id (Qed_error.to_string err)
            | Event.CharacterSelected { user_id; _ } ->
                Publisher.publish_system_message_to_user state user_id (Qed_error.to_string err)
            | Event.CharacterListRequested { user_id } ->
                Publisher.publish_system_message_to_user state user_id "Failed to retrieve character list"
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
  let* init_result = Ecs.World.init state.redis_conn in
  match init_result with
  | Ok () ->
      let* () = register_ecs_systems state in
      Lwt.async (fun () -> subscribe_to_player_commands state);
      game_loop state
  | Error e ->
      let* () = Lwt_io.printl (Printf.sprintf "World initialization error: %s" (Base.Error.to_string_hum e)) in
      Stdio.print_endline ("[ERROR] World initialization error: " ^ Base.Error.to_string_hum e);
      Lwt.return_unit
