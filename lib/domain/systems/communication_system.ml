module Character_list_communication_system = struct
  (* Handles sending character list to clients *)
  
  let handle_character_list state user_id characters =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        (* Send character list to the client *)
        client.Client.send (Protocol.CharacterList { characters })
    | None -> 
        (* User not connected, nothing to do *)
        Lwt.return_unit

  (* System implementation for ECS *)
  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Character_creation_communication_system = struct
  (* Handles sending character creation responses to clients *)
  
  let handle_character_created state user_id character =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        client.Client.send (Protocol.CharacterCreated { character })
    | None -> Lwt.return_unit

  let handle_character_creation_failed state user_id error =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        client.Client.send (Protocol.CharacterCreationFailed { error })
    | None -> Lwt.return_unit

  (* System implementation for ECS *)
  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Character_selection_communication_system = struct
  (* Handles sending character selection responses to clients *)
  
  let handle_character_selected state user_id character =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        client.Client.send (Protocol.CharacterSelected { character })
    | None -> Lwt.return_unit

  let handle_character_selection_failed state user_id error =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        client.Client.send (Protocol.CharacterSelectionFailed { error })
    | None -> Lwt.return_unit

  (* System implementation for ECS *)
  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end
