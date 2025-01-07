open Base

let handler state websocket =
  let open Game in
  let client_id =
    Digestif.SHA256.(
      digest_string (Int64.of_int (Random.bits ()) |> Int64.to_string) |> to_hex)
  in
  let send_message msg = Dream.send websocket msg in
  let client = Client.create client_id send_message in

  State.add_client state client;

  let rec process_messages () =
    match%lwt Dream.receive websocket with
    | Some msg -> (
        let open Protocol.Message in
        let yojson_msg = Yojson.Safe.from_string msg in
        let message = client_message_of_yojson yojson_msg in
        match message with
        | Ok message ->
            let%lwt () = Message_handler.handle_message state client message in
            process_messages ()
        | Error err ->
            ignore (Stdio.print_endline ("Parse error: " ^ err));
            let%lwt () =
              client.send
                (Protocol.Message.Error
                   {
                     message =
                       Qed_error.auth_error_to_string InvalidMessageFormat;
                   }
                |> Protocol.Message.server_message_to_yojson
                |> Yojson.Safe.to_string)
            in
            process_messages ())
    | None ->
        State.remove_client state client_id;
        Lwt.return_unit
  in
  process_messages ()

let start db =
  let open Game in
  let state = State.create db in

  (* Start game loop *)
  Lwt.async (fun () -> Loop.run state);

  (* Configure web server *)
  Dream.run ~interface:"0.0.0.0" ~port:3030
  @@ Dream.logger
  @@ Dream.router
       [ Dream.get "/websocket" (fun _ -> Dream.websocket (handler state)) ]
