module Character_list_system = struct

  let find_client_by_user_id connection_manager user_id =
    let clients = connection_manager.Connection_manager.clients in
    Base.Hashtbl.fold clients ~init:None ~f:(fun ~key:_ ~data:client acc ->
      match acc with
      | Some _ -> acc
      | None ->
          match client.Client.auth_state with
          | Client.Authenticated { user_id = client_user_id; _ } when Base.String.equal client_user_id user_id ->
              Some client
          | _ -> None
    )

  let handle_character_list_requested state user_id =
    match%lwt Character.find_all_by_user ~user_id with
    | Ok characters ->
        (* Convert the characters to the protocol format *)
        let characters' = Base.List.map characters ~f:Types.character_of_model in
        
        (* Find the client associated with this user_id *)
        let client_opt = find_client_by_user_id state.State.connection_manager user_id in
        (match client_opt with
        | Some client ->
            (* Send the character list to the client *)
            client.Client.send (Protocol.CharacterList { characters = characters' })
        | None ->
            (* User not connected, nothing to do *)
            Lwt.return_unit)
    | Error error ->
        let%lwt () = Lwt_io.printl (Printf.sprintf "Error: %s" (Qed_error.to_string error)) in
        (* Handle the error - try to send an error to the client if they're still connected *)
        let client_opt = find_client_by_user_id state.State.connection_manager user_id in
        (match client_opt with
        | Some client ->
            client.Client.send (Protocol.CharacterListFailed 
              { error = Qed_error.to_yojson error })
        | None -> Lwt.return_unit)

  (* System implementation for ECS *)
  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 