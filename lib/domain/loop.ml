open Lwt.Syntax

let get_area_by_id_opt (area_id : string) =
  match%lwt Area.find_by_id area_id with
  | Error _ -> Lwt.return_none
  | Ok area -> (
      match%lwt Area.get_exits area with
      | Error _ -> Lwt.return_none
      | Ok exits ->
          let area' = Types.area_of_model area exits in
          Lwt.return_some area')

let broadcast_area_update (state : State.t) (area_id : string) =
  match%lwt get_area_by_id_opt area_id with
  | None -> Lwt.return_unit
  | Some area ->
      let update = Protocol.Area { area } in
      Connection_manager.broadcast_to_room state.connection_manager area_id
        update;
      Lwt.return_unit

let handle_character_movement (state : State.t) (client : Client.t) old_area_id
    new_area_id =
  (* Remove from old room *)
  Connection_manager.remove_from_room state.connection_manager client.Client.id;

  (* Add to new room *)
  Connection_manager.add_to_room state.connection_manager
    ~client_id:client.Client.id ~room_id:new_area_id;

  (* Send departure/arrival messages to both rooms *)
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { character_id = None; _ } -> Lwt.return_unit
  | Client.Authenticated { character_id = Some char_id; _ } -> (
      match%lwt Character.find_by_id char_id with
      | Error _ -> Lwt.return_unit
      | Ok character -> (
          let%lwt departure_result =
            Communication.create ~message_type:Communication.System
              ~sender_id:None
              ~content:(character.name ^ " has left the area.")
              ~area_id:(Some old_area_id)
          in
          let%lwt arrival_result =
            Communication.create ~message_type:Communication.System
              ~sender_id:None
              ~content:(character.name ^ " has arrived.")
              ~area_id:(Some new_area_id)
          in
          match (departure_result, arrival_result) with
          | Error e, _ | _, Error e ->
              ignore
                (Stdio.print_endline
                   (Yojson.Safe.to_string (Communication.error_to_yojson e)));
              Lwt.return_unit
          | Ok departure_msg, Ok arrival_msg -> (
              let departure_msg' = Types.chat_message_of_model departure_msg in
              let arrival_msg' = Types.chat_message_of_model arrival_msg in
              Connection_manager.broadcast_to_room state.connection_manager
                old_area_id
                (Protocol.ChatMessage { message = departure_msg' });
              Connection_manager.broadcast_to_room state.connection_manager
                new_area_id
                (Protocol.ChatMessage { message = arrival_msg' });
              match%lwt Communication.find_by_area_id new_area_id with
              | Ok messages ->
                  let messages' =
                    List.map Types.chat_message_of_model messages
                  in
                  let%lwt () =
                    client.send (Protocol.ChatHistory { messages = messages' })
                  in
                  Lwt.return_unit
              | Error _ -> Lwt.return_unit)))

let handle_character_creation (state : State.t) (client : Client.t)
    (name : string) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { user_id; _ } -> (
      let%lwt result = Character.create ~user_id ~name in
      match result with
      | Ok character -> (
          let () = Client.set_character client character.id in
          let character' = Types.character_of_model character in
          let character_json = Types.character_to_yojson character' in
          let%lwt () = client.send (Protocol.CharacterCreated character_json) in
          (* Add to starting room *)
          Connection_manager.add_to_room state.connection_manager
            ~client_id:client.Client.id
            ~room_id:"00000000-0000-0000-0000-000000000000";
          (* Send initial area info *)
          match%lwt get_area_by_id_opt character.location_id with
          | None -> Lwt.return_unit
          | Some area -> (
              let%lwt () = client.send (Protocol.Area { area }) in
              match%lwt Communication.find_by_area_id character.location_id with
              | Ok messages ->
                  let messages' =
                    List.map Types.chat_message_of_model messages
                  in
                  let%lwt () =
                    client.send (Protocol.ChatHistory { messages = messages' })
                  in
                  Lwt.return_unit
              | Error _ -> Lwt.return_unit))
      | Error error ->
          let error_json = Character.error_to_yojson error in
          let%lwt () =
            client.send
              (Protocol.CharacterCreationFailed { error = error_json })
          in
          Lwt.return_unit)

let handle_character_list (_state : State.t) (client : Client.t) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { user_id; _ } -> (
      match%lwt Character.find_all_by_user ~user_id with
      | Ok characters ->
          let characters' = List.map Types.character_of_model characters in
          let%lwt () =
            client.send (Protocol.CharacterList { characters = characters' })
          in
          Lwt.return_unit
      | Error error ->
          let error_json = Character.error_to_yojson error in
          let%lwt () =
            client.send (Protocol.CharacterListFailed { error = error_json })
          in
          Lwt.return_unit)

let handle_character_select (state : State.t) (client : Client.t)
    (character_id : string) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated _ -> (
      match%lwt Character.find_by_id character_id with
      | Ok character -> (
          let () = Client.set_character client character.id in
          let character' = Types.character_of_model character in
          let%lwt () =
            client.send (Protocol.CharacterSelected { character = character' })
          in
          (* Add to character's current room *)
          Connection_manager.add_to_room state.connection_manager
            ~client_id:client.Client.id ~room_id:character.location_id;
          (* Send area information *)
          match%lwt get_area_by_id_opt character.location_id with
          | None -> Lwt.return_unit
          | Some area -> (
              let%lwt () = client.send (Protocol.Area { area }) in
              (* Send arrival message to room *)
              match%lwt Communication.find_by_area_id character.location_id with
              | Ok messages ->
                  let messages' =
                    List.map Types.chat_message_of_model messages
                  in
                  let%lwt () =
                    client.send (Protocol.ChatHistory { messages = messages' })
                  in
                  Lwt.return_unit
              | Error e ->
                  let error_json = Communication.error_to_yojson e in
                  ignore
                    (Stdio.printf "Error: %s\n"
                       (Yojson.Safe.to_string error_json));
                  Lwt.return_unit))
      | Error error ->
          let error_json = Character.error_to_yojson error in
          let%lwt () =
            client.send
              (Protocol.CharacterSelectionFailed { error = error_json })
          in
          Lwt.return_unit)

let handle_command (state : State.t) (client : Client.t) (command_str : string)
    =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { character_id = None; _ } ->
      let%lwt () =
        client.send
          (Protocol.CommandFailed
             { error = "You must select a character first" })
      in
      Lwt.return_unit
  | Authenticated { character_id = Some character_id; _ } -> (
      let open Types in
      match parse_command command_str with
      | Move { direction } -> (
          match%lwt Character.find_by_id character_id with
          | Ok character -> (
              let old_location = character.location_id in
              match%lwt Character.move ~character_id ~direction with
              | Error _ ->
                  let%lwt () =
                    client.send
                      (Protocol.CommandFailed
                         { error = "Cannot move in that direction" })
                  in
                  Lwt.return_unit
              | Ok new_location -> (
                  let%lwt () =
                    handle_character_movement state client old_location
                      new_location
                  in
                  match%lwt get_area_by_id_opt new_location with
                  | None -> Lwt.return_unit
                  | Some area ->
                      let%lwt () = client.send (Protocol.Area { area }) in
                      Lwt.return_unit))
          | Error _ -> Lwt.return_unit)
      | Help ->
          let%lwt () =
            client.send
              (Protocol.CommandSuccess
                 {
                   message =
                     "Available commands:\n\
                      n, s, e, w, u, d - Move in a direction\n\
                      say <message> - Say something\n\
                      emote <action> - Perform an action\n\
                      look - Look at current room\n\
                      help - Show this message";
                 })
          in
          Lwt.return_unit
      | Unknown cmd ->
          let%lwt () =
            client.send
              (Protocol.CommandFailed { error = "Unknown command: " ^ cmd })
          in
          Lwt.return_unit)

let handle_chat (state : State.t) (client : Client.t) message message_type =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { character_id = None; _ } ->
      let%lwt () =
        client.send
          (Protocol.CommandFailed
             { error = "You must select a character first" })
      in
      Lwt.return_unit
  | Authenticated { character_id = Some character_id; _ } -> (
      match%lwt Character.find_by_id character_id with
      | Ok character -> (
          let%lwt message_result =
            Communication.create ~message_type ~sender_id:(Some character_id)
              ~content:message ~area_id:(Some character.location_id)
          in
          match message_result with
          | Ok msg ->
              let chat_message =
                Protocol.ChatMessage
                  {
                    message =
                      {
                        sender_id = Some character_id;
                        message_type;
                        content = message;
                        timestamp = Ptime.to_float_s msg.timestamp;
                        area_id = Some character.location_id;
                      };
                  }
              in
              Connection_manager.broadcast_to_room state.connection_manager
                character.location_id chat_message;
              Lwt.return_unit
          | Error _ -> Lwt.return_unit)
      | Error _ -> Lwt.return_unit)

let handle_request_chat_history (_state : State.t) (client : Client.t) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { character_id = None; _ } ->
      let%lwt () =
        client.send
          (Protocol.CommandFailed
             { error = "You must select a character first" })
      in
      Lwt.return_unit
  | Authenticated { character_id = Some character_id; _ } -> (
      match%lwt Character.find_by_id character_id with
      | Ok character -> (
          match%lwt Communication.find_by_area_id character.location_id with
          | Ok messages -> 
              let messages' = List.map Types.chat_message_of_model messages in
              let%lwt () =
                client.send (Protocol.ChatHistory { messages = messages' })
              in
              Lwt.return_unit
          | Error _ -> Lwt.return_unit)
      | Error _ -> Lwt.return_unit)

let process_messages (state : State.t) =
  let rec process_all () =
    match%lwt Queue.pop_opt state.message_queue with
    | None -> Lwt.return_unit
    | Some { message; client } ->
        let%lwt () =
          match message with
          | CreateCharacter { name } ->
              handle_character_creation state client name
          | SelectCharacter { character_id } ->
              handle_character_select state client character_id
          | ListCharacters -> handle_character_list state client
          | Command { command } -> handle_command state client command
          | SendChat { message } ->
              handle_chat state client message Communication.Chat
          | SendEmote { message } ->
              handle_chat state client message Communication.Emote
          | SendSystem { message } ->
              handle_chat state client message Communication.System
          | RequestChatHistory ->
              handle_request_chat_history state client
        in
        process_all ()
  in
  process_all ()

let tick (state : State.t) =
  (* Handle messages *)
  let* () = process_messages state in
  let delta = Unix.gettimeofday () -. state.last_tick in
  let* () = Lwt_unix.sleep (Float.max 0.0 (0.01 -. delta)) in
  State.update_tick state;
  (* ignore (Stdio.print_endline (Printf.sprintf "Tick: %f" delta)); *)
  Lwt.return_unit

let rec run (state : State.t) =
  Lwt.catch
    (fun () ->
      let%lwt () = tick state in
      run state)
    (fun exn ->
      Stdio.eprintf "Game loop error: %s\n" (Base.Exn.to_string exn);
      run state)
