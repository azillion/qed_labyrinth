module Handler : Client_handler.S = struct
  let send_area_info (client : Client.t) (area_id : string) =
    match%lwt Client_handler.get_area_by_id_opt area_id with
    | None -> Lwt.return_unit
    | Some area -> (
        let%lwt () = client.send (Protocol.Area { area }) in
        match%lwt Communication.find_by_area_id area_id with
        | Ok messages ->
            let messages' = List.map Types.chat_message_of_model messages in
            client.send (Protocol.ChatHistory { messages = messages' })
        | Error _ -> Lwt.return_unit)

  (* Movement handling *)
  let handle_character_movement (state : State.t) (client : Client.t) direction
      =
    Client_handler.with_character_check client (fun (character : Character.t) ->
        let old_area_id = character.location_id in
        match%lwt Character.move ~character_id:character.id ~direction with
        | Error _ ->
            Client_handler.send_error client "Cannot move in that direction"
        | Ok new_area_id -> (
            (* Update room connections *)
            Connection_manager.remove_from_room state.connection_manager
              client.Client.id;
            Connection_manager.add_to_room state.connection_manager
              ~client_id:client.Client.id ~room_id:new_area_id;

            (* Create movement messages *)
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
            | Ok departure_msg, Ok arrival_msg ->
                (* Broadcast movement messages *)
                let departure_msg' =
                  Types.chat_message_of_model departure_msg
                in
                let arrival_msg' = Types.chat_message_of_model arrival_msg in
                Connection_manager.broadcast_to_room state.connection_manager
                  old_area_id
                  (Protocol.ChatMessage { message = departure_msg' });
                Connection_manager.broadcast_to_room state.connection_manager
                  new_area_id
                  (Protocol.ChatMessage { message = arrival_msg' });

                (* Send new area info to moving character *)
                let%lwt () = send_area_info client new_area_id in
                let status = Status_frame.of_character character in
                let%lwt () = client.send (Protocol.Status { status = Types.status_of_model status }) in
                Lwt.return_unit))

  (* Character creation/selection *)
  let handle_character_creation (state : State.t) (client : Client.t)
      (name : string) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { user_id; _ } -> (
        match%lwt Character.create ~user_id ~name with
        | Ok character ->
            let () = Client.set_character client character.id in
            let character' = Types.character_of_model character in
            let%lwt () =
              client.send
                (Protocol.CharacterCreated
                   (Types.character_to_yojson character'))
            in

            (* Add to starting room and send initial info *)
            Connection_manager.add_to_room state.connection_manager
              ~client_id:client.Client.id
              ~room_id:"00000000-0000-0000-0000-000000000000";
            let%lwt () = send_area_info client character.location_id in
            let status = Status_frame.of_character character in
            let%lwt () = client.send (Protocol.Status { status = Types.status_of_model status }) in
            Lwt.return_unit
        | Error error ->
            client.send
              (Protocol.CharacterCreationFailed
                 { error = Character.error_to_yojson error }))

  let handle_character_list (client : Client.t) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { user_id; _ } -> (
        match%lwt Character.find_all_by_user ~user_id with
        | Ok characters ->
            let characters' = List.map Types.character_of_model characters in
            client.send (Protocol.CharacterList { characters = characters' })
        | Error error ->
            client.send
              (Protocol.CharacterListFailed
                 { error = Character.error_to_yojson error }))

  let handle_character_select (state : State.t) (client : Client.t)
      (character_id : string) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { user_id; _ } -> (
        match%lwt User.find_by_id user_id with
        | Error _ ->
            client.send
              (Protocol.CharacterSelectionFailed
                 { error = Character.error_to_yojson Character.UserNotFound })
        | Ok user ->
            let%lwt () = client.send (Protocol.UserRole { role = User.string_of_role user.role }) in
        match%lwt Character.find_by_id character_id with
        | Ok character ->
            let () = Client.set_character client character.id in
            let character' = Types.character_of_model character in
            let%lwt () =
              client.send
                (Protocol.CharacterSelected { character = character' })
            in

            (* Add to character's current room and send info *)
            Connection_manager.add_to_room state.connection_manager
              ~client_id:client.Client.id ~room_id:character.location_id;
            let%lwt () = send_area_info client character.location_id in
            let status = Status_frame.of_character character in
            let%lwt () = client.send (Protocol.Status { status = Types.status_of_model status }) in
            Lwt.return_unit
        | Error error ->
            client.send
              (Protocol.CharacterSelectionFailed
                 { error = Character.error_to_yojson error }))

  (* Main message handler *)
  let handle state client msg =
    let open Protocol in
    match msg with
    | CreateCharacter { name } -> handle_character_creation state client name
    | SelectCharacter { character_id } ->
        handle_character_select state client character_id
    | ListCharacters -> handle_character_list client
    | Move { direction } -> handle_character_movement state client direction
    | _ -> Lwt.return_unit
end
