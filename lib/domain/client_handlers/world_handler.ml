module Handler : Client_handler.S = struct
  (* Helper functions *)
  let send_error (client : Client.t) error =
    client.send (Protocol.CommandFailed { error })


  let handle_world_generation (client : Client.t) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { character_id = None; _ } -> send_error client "You must select a character first"
    | Authenticated { user_id; character_id = Some character_id } -> (
        match%lwt User.find_by_id user_id with
        | Error _ -> Lwt.return_unit
      | Ok user -> (
          match user.role with
          | Player -> send_error client "You are not authorized to generate the world"
          | Admin -> send_error client "You are not authorized to generate the world"
          | SuperAdmin -> (
              match%lwt Character.find_by_id character_id with
              | Error _ -> send_error client "You must select a character first"
              | Ok character ->
                  let%lwt message_result = 
                    Communication.create
                      ~message_type:Communication.CommandSuccess
                      ~sender_id:None
                      ~content:"World generation started"
                      ~area_id:(Some character.location_id)
                  in
                  match message_result with
                  | Ok msg ->
                      client.send (Protocol.CommandSuccess { 
                        message = { 
                          sender_id = None;
                          message_type = Communication.CommandSuccess;
                          content = msg.content;
                          timestamp = Ptime.to_float_s msg.timestamp;
                          area_id = msg.area_id;
                        }
                      })
                  | Error _ -> Lwt.return_unit
          )))

  (* Main message handler *)
  let handle (_state : State.t) (client : Client.t) msg =
    let open Protocol in
    match msg with
    | RequestWorldGeneration -> handle_world_generation client
    | _ -> Lwt.return_unit
end
