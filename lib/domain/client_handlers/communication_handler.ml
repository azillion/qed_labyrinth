module Handler : Client_handler.S = struct
  (* Helper functions *)
  let send_error client error =
    client.Client.send (Protocol.CommandFailed { error })

  let handle_chat (state : State.t) (client : Client.t) message message_type =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { character_id = None; _ } ->
        send_error client "You must select a character first"
    | Authenticated { character_id = Some character_id; _ } -> (
        match message_type with
        | Communication.CommandSuccess -> (
            let help_message = "Available commands:\n" ^
              "/help - Show this help message\n" ^
              "/me <action> - Perform an emote\n" ^
              "/say <message> - Say something (or just type without /say)\n"
            in
            let%lwt message_result =
              match%lwt Character.find_by_id character_id with
              | Ok character ->
                  Communication.create 
                    ~message_type:Communication.CommandSuccess
                    ~sender_id:None
                    ~content:help_message 
                    ~area_id:(Some character.location_id)
              | Error _ -> Lwt.return_error (Communication.DatabaseError "Character not found")
            in
            match message_result with
            | Ok msg ->
                let chat_message =
                  Protocol.ChatMessage
                    {
                      message = {
                        sender_id = None;
                        message_type = Communication.CommandSuccess;
                        content = help_message;
                        timestamp = Ptime.to_float_s msg.timestamp;
                        area_id = msg.area_id;
                      };
                    }
                in
                client.send chat_message
            | Error _ -> Lwt.return_unit)
        | _ -> (
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
        | Error _ -> Lwt.return_unit))

  let handle_request_chat_history (_state : State.t) (client : Client.t) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { character_id = None; _ } ->
        send_error client "You must select a character first"
    | Authenticated { character_id = Some character_id; _ } -> (
        match%lwt Character.find_by_id character_id with
        | Ok character -> (
            match%lwt Communication.find_by_area_id character.location_id with
            | Ok messages ->
                let messages' = List.map Types.chat_message_of_model messages in
                client.send (Protocol.ChatHistory { messages = messages' })
            | Error _ -> Lwt.return_unit)
        | Error _ -> Lwt.return_unit)

  (* Main message handler *)
  let handle state client msg =
    let open Protocol in
    match msg with
    | SendChat { message } ->
        handle_chat state client message Communication.Chat
    | SendEmote { message } ->
        handle_chat state client message Communication.Emote
    | SendSystem { message } ->
        handle_chat state client message Communication.System
    | RequestChatHistory -> handle_request_chat_history state client
    | Help -> handle_chat state client "" Communication.CommandSuccess
    | Unknown cmd ->
        let%lwt () =
          client.send
            (Protocol.CommandFailed { error = "Unknown command: " ^ cmd })
        in
        Lwt.return_unit
    | _ -> Lwt.return_unit
end
