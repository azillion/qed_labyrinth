module Handler : Client_handler.S = struct
  (* Helper functions *)
  let send_error (client : Client.t) error =
    client.send (Protocol.CommandFailed { error })

  let send_message (client : Client.t) message message_type (character : Character.t) =
    let%lwt message_result =
      Communication.create
        ~message_type
        ~sender_id:(Some character.id)
        ~content:message
        ~area_id:(Some character.location_id)
    in
    match message_result with
    | Error _ -> Lwt.return_unit
    | Ok msg -> 
      match message_type with
      | Communication.CommandSuccess -> client.send (Protocol.CommandSuccess {
        message = {
          sender_id = None;
          message_type = Communication.CommandSuccess;
          content = msg.content;
          timestamp = Ptime.to_float_s msg.timestamp;
          area_id = msg.area_id;
        }
      })
      | _ -> Lwt.return_unit

  let handle_world_generation (client : Client.t) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { character_id = None; _ } -> send_error client "You must select a character first"
    | Authenticated { user_id; character_id = Some character_id } -> 
        match%lwt User.find_by_id user_id with
        | Error _ -> Lwt.return_unit
      | Ok user -> 
          match user.role with
          | Player -> send_error client "You are not authorized to generate the world"
          | Admin -> send_error client "You are not authorized to generate the world"
          | SuperAdmin -> 
              match%lwt Character.find_by_id character_id with
              | Error _ -> send_error client "You must select a character first"
              | Ok character ->
                  send_message client "World generation started" Communication.CommandSuccess character

  let handle_world_deletion (client : Client.t) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { character_id = None; _ } -> send_error client "You must select a character first"
    | Authenticated { user_id; character_id = Some character_id } -> 
        match%lwt User.find_by_id user_id with
        | Error _ -> Lwt.return_unit
      | Ok user -> 
          match user.role with
          | Player -> send_error client "You are not authorized to delete the world"
          | Admin -> send_error client "You are not authorized to delete the world"
          | SuperAdmin -> 
              match%lwt Character.find_by_id character_id with
              | Error _ -> send_error client "You must select a character first"
              | Ok character ->
                  match%lwt Area.delete_all_except_starting_area character.location_id with
                  | Error _ -> send_error client "Failed to delete the world"
                  | Ok () -> send_message client "World deleted" Communication.CommandSuccess character

  (* Main message handler *)
  let handle (_state : State.t) (client : Client.t) msg =
    let open Protocol in
    match msg with
    | RequestWorldGeneration -> handle_world_generation client
    | RequestWorldDeletion -> handle_world_deletion client
    | _ -> Lwt.return_unit
end
