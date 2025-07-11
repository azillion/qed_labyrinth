open Lwt.Syntax
open Base
open Error_utils

module Queue = Infra.Queue

let string_of_event_type (event: Event.t) =
  match event with
  | CreateCharacter _ -> "CreateCharacter"
  | CharacterCreated _ -> "CharacterCreated"
  | CharacterSelected _ -> "CharacterSelected"
  | Move _ -> "Move"
  | Say _ -> "Say"
  | CharacterListRequested _ -> "CharacterListRequested"
  | AreaQuery _ -> "AreaQuery"
  | AreaQueryResult _ -> "AreaQueryResult"
  | LoadAreaIntoECS _ -> "LoadAreaIntoECS"
  | PlayerMoved _ -> "PlayerMoved"
  | UpdateAreaPresence _ -> "UpdateAreaPresence"
  | AreaCreated _ -> "AreaCreated"
  | AreaCreationFailed _ -> "AreaCreationFailed"
  | ExitCreated _ -> "ExitCreated"
  | ExitCreationFailed _ -> "ExitCreationFailed"
  | SendMovementFailed _ -> "SendMovementFailed"
  | CharacterList _ -> "CharacterList"
  | LoadCharacterIntoECS _ -> "LoadCharacterIntoECS"
  | UnloadCharacterFromECS _ -> "UnloadCharacterFromECS"
  | SendChatHistory _        -> "SendChatHistory"
  | RequestChatHistory _     -> "RequestChatHistory"
  | Announce _               -> "Announce"
  | Tell _                   -> "Tell"
  | Emote _                  -> "Emote"
  | CharacterCreationFailed _-> "CharacterCreationFailed"
  | CharacterSelectionFailed _-> "CharacterSelectionFailed"
  | AreaQueryFailed _        -> "AreaQueryFailed"
  | _ -> "OtherEvent"

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
  let () =
    let payload_type = match proto_event.payload with
      | Some (Move _) -> "Move"
      | Some (Say _) -> "Say"
      | Some (Create_character _) -> "CreateCharacter"
      | Some (List_characters) -> "ListCharacters"
      | Some (Select_character _) -> "SelectCharacter"
      | None -> "None"
    in
    Stdio.printf "[DEBUG] Converting protobuf event with payload type: %s\n" payload_type
  in
  match proto_event.payload with
  | None -> None
  | Some payload ->
      match payload with
      | Move move_cmd ->
          let direction = direction_of_proto move_cmd.direction in
          Some (Event.Move { user_id = proto_event.user_id; direction })
      | Say say_cmd ->
          Some (Event.Say { user_id = proto_event.user_id; content = say_cmd.content })
      | Create_character create_cmd ->
          (match Int32.to_int create_cmd.might, Int32.to_int create_cmd.finesse, Int32.to_int create_cmd.wits, Int32.to_int create_cmd.grit, Int32.to_int create_cmd.presence with
          | Some might, Some finesse, Some wits, Some grit, Some presence ->
              Some (Event.CreateCharacter { 
                user_id = proto_event.user_id; 
                name = create_cmd.name; 
                description = ""; 
                starting_area_id = "00000000-0000-0000-0000-000000000000"; 
                might = might; 
                finesse = finesse; 
                wits = wits; 
                grit = grit; 
                presence = presence 
              })
          | _ -> None)
      | List_characters ->
          Some (Event.CharacterListRequested { user_id = proto_event.user_id })
      | Select_character select_cmd ->
          Some (Event.CharacterSelected { user_id = proto_event.user_id; character_id = select_cmd.character_id })

(* Redis subscriber function *)
let subscribe_to_player_commands (state : State.t) =
  let open Lwt.Syntax in
  let redis_host =
    try Stdlib.Sys.getenv "REDIS_HOST"
    with _ -> failwith "REDIS_HOST environment variable is not set"
  in
  let%lwt subscriber_conn = Redis_lwt.Client.connect { host = redis_host; port = 6379 } in
  let%lwt () = Redis_lwt.Client.subscribe subscriber_conn ["player_commands"] in
  let%lwt () = Lwt_io.printl "[DEBUG] Subscribed to player_commands" in
  let reply_stream = Redis_lwt.Client.stream subscriber_conn in
  (* Helper to stringify Redis replies for debugging *)
  (* let string_of_redis_reply (r : Redis_lwt.Client.reply) : string =
    match r with
    | `Bulk None -> "Bulk nil"
    | `Bulk (Some s) -> Printf.sprintf "Bulk(%d)" (String.length s)
    | `Status s -> "Status(" ^ s ^ ")"
    | `Int i -> "Int(" ^ Int.to_string i ^ ")"
    | `Int64 i -> "Int64(" ^ Int64.to_string i ^ ")"
    | `Error e -> "Error(" ^ e ^ ")"
    | `Multibulk l -> "Multibulk(len=" ^ Int.to_string (List.length l) ^ ")"
    | `Moved _ -> "Moved"
    | `Ask _ -> "Ask"
  in *)
  Lwt_stream.iter_s (fun reply_parts ->
    (* Log summary of the parts *)
    (* let parts_desc = String.concat ~sep:", " (List.map reply_parts ~f:string_of_redis_reply) in
    let%lwt () = Lwt_io.printl ("[TRACE] Reply parts: [" ^ parts_desc ^ "]") in *)
    match reply_parts with
    | [`Bulk (Some "message"); `Bulk (Some channel); `Bulk (Some message_content)] ->
        let%lwt () = Lwt_io.printl (Printf.sprintf "[DEBUG] Received message on channel '%s'" channel) in
        (try
          let* () = Lwt_io.printl "[DEBUG] Attempting to deserialize Protobuf message." in
          let proto_event = Schemas_generated.Input.decode_pb_input_event (Pbrt.Decoder.of_string message_content) in
          match event_of_protobuf proto_event with
          | Some event ->
              let* () = Infra.Queue.push state.event_queue event in
              let* () = Lwt_io.printl "[DEBUG] Pushed event to internal queue." in
              Lwt.return_unit
          | None ->
              let* () = Lwt_io.printl "[ERROR] Protobuf message resulted in no engine event." in
              Lwt.return_unit
        with exn ->
          let* () = Lwt_io.printl (Printf.sprintf "[FATAL] Deserialization failed: %s" (Base.Exn.to_string exn)) in
          Lwt.return_unit)
    | [`Bulk (Some "subscribe"); _channel; _] ->
        (* Subscription ack *)
        Lwt.return_unit
    | _ ->
        let%lwt () = Lwt_io.printl "[DEBUG] Unhandled reply pattern from Redis" in
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
  
  | Event.AreaQuery { user_id; area_id } ->
      Area_management_system.Area_query_system.handle_area_query state user_id area_id
  | Event.AreaQueryResult { user_id; area } ->
      Area_management_system.Area_query_communication_system.handle_area_query_result state user_id area
  | Event.LoadAreaIntoECS { area_id } ->
      Area_loading_system.handle_load_area area_id
  
  | Event.Move { user_id; direction } ->
      Movement_system.System.handle_move state user_id direction
  | Event.PlayerMoved { user_id; old_area_id; new_area_id; direction } ->
      Presence_system.System.handle_player_moved state user_id old_area_id new_area_id direction
  | Event.SendMovementFailed { user_id; reason } ->
      let open Lwt_result.Syntax in
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
      let open Lwt_result.Syntax in
      let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[EVENT] CharacterCreated user=%s char_id=%s. Triggering CharacterSelected." user_id character_id)) in
      let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.CharacterSelected { user_id; character_id })) in
      Lwt_result.return ()
  
  (* Add other event handlers here as they are refactored *)
  | _ -> 
    let* () = Lwt_io.printl (Printf.sprintf "[WARNING] Unhandled event: %s" (string_of_event_type event)) in
    Lwt_result.return () (* Ignore unhandled events for now *)

(* Replace the old process_events with this new one *)
let process_events (state : State.t) =
  let rec process_all () =
    match%lwt Infra.Queue.pop_opt state.event_queue with
    | None -> Lwt.return_unit
    | Some event ->
        let%lwt () = Lwt_io.printl (Printf.sprintf "[DEBUG] Popped from queue, now processing event: %s" (string_of_event_type event)) in
        let%lwt result = process_event state event in
        let%lwt () = match result with
        | Ok () -> Lwt.return_unit (* Success, continue *)
        | Error err ->
            let err_str = Qed_error.to_string err in
            let* () = Lwt_io.printl (Printf.sprintf "[EVENT_ERROR] %s" err_str) in
            (* Try to extract user_id from the failed event to notify them *)
            let user_id_opt =
              match event with
              | CreateCharacter { user_id; _ } -> Some user_id
              | CharacterSelected { user_id; _ } -> Some user_id
              | CharacterListRequested { user_id } -> Some user_id
              | Move { user_id; _ } -> Some user_id
              | Say { user_id; _ } -> Some user_id
              | AreaQuery { user_id; _ } -> Some user_id
              (* Add other user-facing events here as they are created *)
              | _ -> None
            in
            (match user_id_opt with
            | Some user_id ->
                let%lwt _ = Publisher.publish_system_message_to_user state user_id ("Error: " ^ err_str) in
                Lwt.return_unit
            | None ->
                (* Event was not user-specific, so just log it. *)
                Lwt.return_unit)
        in
        process_all ()
  in
  process_all ()

let register_ecs_systems () =
  (* Register your ECS systems here *)

  let open Lwt.Syntax in
  let* () = Initialization_system.Starting_area_initialization_system.initialize_starting_area_once () in
  
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
      let* () = register_ecs_systems () in
      Lwt.join [subscribe_to_player_commands state; game_loop state]
  | Error e ->
      let* () = Lwt_io.printl (Printf.sprintf "World initialization error: %s" (Base.Error.to_string_hum e)) in
      Stdio.print_endline ("[ERROR] World initialization error: " ^ Base.Error.to_string_hum e);
      Lwt.return_unit
