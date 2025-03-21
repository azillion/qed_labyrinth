open Base

let handler (state : Qed_domain.State.t) user_id websocket =
  let client_id =
    Digestif.SHA256.(
      digest_string (Int64.of_int (Random.bits ()) |> Int64.to_string) |> to_hex)
  in
  let send_message msg = Dream.send websocket msg in
  let open Qed_domain in
  let client = Client.create client_id send_message (Some websocket) in
  Client.set_authenticated client user_id;
  Connection_manager.add_client state.connection_manager client;

  let rec process_messages () =
    try
      match%lwt Dream.receive websocket with
      | Some msg -> (
          let open Qed_domain.Protocol in
          let yojson_msg = Yojson.Safe.from_string msg in
          let message = client_message_of_yojson yojson_msg in
          match message with
          | Ok message -> (
              match message with
              | Command { command } ->
                  let message' = Qed_domain.Protocol.parse_command command in
                  let%lwt () = Infra.Queue.push state.client_message_queue { message = message'; client } in
                  process_messages ()
              | _ ->
                  let%lwt () = Infra.Queue.push state.client_message_queue { message; client } in
                  process_messages ())
          | Error err ->
              ignore (Stdio.print_endline ("Parse error: " ^ err));
              process_messages ())
      | None ->
          Connection_manager.remove_client state.connection_manager client_id;
          Lwt.return_unit
    with
    | exn ->
        let error_msg = Exn.to_string exn in
        ignore (Stdio.print_endline ("Websocket error: " ^ error_msg));
        Connection_manager.remove_client state.connection_manager client_id;
        Lwt.return_unit
  in
  process_messages ()
