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
    match%lwt Dream.receive websocket with
    | Some msg -> (
        let open Qed_domain.Protocol in
        let yojson_msg = Yojson.Safe.from_string msg in
        let message = client_message_of_yojson yojson_msg in
        match message with
        | Ok message ->
            let%lwt () = Queue.push state.message_queue message client in
            process_messages ()
        | Error err ->
            ignore (Stdio.print_endline ("Parse error: " ^ err));
            process_messages ())
    | None ->
        Connection_manager.remove_client state.connection_manager client_id;
        Lwt.return_unit
  in
  process_messages ()
