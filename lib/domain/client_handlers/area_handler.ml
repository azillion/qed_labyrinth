module Handler : Client_handler.S = struct
  (* Helper functions *)
  let _send_error (client : Client.t) error =
    client.send (Protocol.CommandFailed { error })

  let _send_area_info (client : Client.t) (area_id : string) =
    match%lwt Utils.get_area_by_id_opt area_id with
    | None -> Lwt.return_unit
    | Some area -> (
        let%lwt () = client.send (Protocol.Area { area }) in
        match%lwt Communication.find_by_area_id area_id with
        | Ok messages ->
            let messages' = List.map Types.chat_message_of_model messages in
            client.send (Protocol.ChatHistory { messages = messages' })
        | Error _ -> Lwt.return_unit)


  let send_admin_map (_client : Client.t) =
    (* let%lwt () = client.send (Protocol.AdminMap { world }) in *)
    Lwt.return_unit

  (* Main message handler *)
  let handle (_state : State.t) (client : Client.t) msg =
    let open Protocol in
    match msg with
    | RequestAdminMap -> send_admin_map client
    | _ -> Lwt.return_unit
end
