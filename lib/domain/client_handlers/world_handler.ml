module Handler : Client_handler.S = struct
  (* Helper functions *)
  let send_error (client : Client.t) error =
    client.send (Protocol.CommandFailed { error })


  let handle_world_generation (client : Client.t) =
    match client.auth_state with
    | Anonymous -> Lwt.return_unit
    | Authenticated { user_id; _ } -> (
        match%lwt User.find_by_id user_id with
        | Error _ -> Lwt.return_unit
      | Ok user -> (
          match user.role with
          | Player -> send_error client "You are not authorized to generate the world"
          | Admin -> send_error client "You are not authorized to generate the world"
          | SuperAdmin -> client.send (Protocol.CommandSuccess { message = "World generation started" })
          ))

  (* Main message handler *)
  let handle (_state : State.t) (client : Client.t) msg =
    let open Protocol in
    match msg with
    | RequestWorldGeneration -> handle_world_generation client
    | _ -> Lwt.return_unit
end
