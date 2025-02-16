module Handler : Client_handler.S = struct
  (* Helper functions *)

  let handle_status_request (_state : State.t) (client : Client.t) =
    Client_handler.with_character_check client (fun character ->
        let status = Status_frame.of_character character in
        client.send (Protocol.Status { status = Types.status_of_model status }))

  (* Main message handler *)
  let handle state client msg =
    let open Protocol in
    match msg with
    | RequestStatusFrame -> handle_status_request state client
    | _ -> Lwt.return_unit
end
