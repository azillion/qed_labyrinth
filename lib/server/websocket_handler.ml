open Base
open Qed_domain

let auth_error_to_string = function
  | User.UserNotFound -> "User not found"
  | InvalidPassword -> "Invalid password"
  | User.EmailTaken -> "Email already taken"
  | UsernameTaken -> "Username already taken"
  | DatabaseError msg -> "Database error occurred" ^ msg

let handler state websocket =
  let client_id =
    Digestif.SHA256.(
      digest_string (Int64.of_int (Random.bits ()) |> Int64.to_string) |> to_hex)
  in
  let send_message msg = Dream.send websocket msg in
  let client = Client.create client_id send_message (Some websocket) in

  Connection_manager.add_client state client;

  let rec process_messages () =
    match%lwt Dream.receive websocket with
    | Some msg -> (
        let open Api.Protocol in
        let yojson_msg = Yojson.Safe.from_string msg in
        let message = client_message_of_yojson yojson_msg in
        match message with
        | Ok _message ->
            Stdio.print_endline "Processing message";
            Stdio.print_endline msg;
            (* let%lwt () = Message_handler.handle_message state client message in *)
            process_messages ()
        | Error err ->
            ignore (Stdio.print_endline ("Parse error: " ^ err));
            process_messages ())
    | None ->
        Connection_manager.remove_client state client_id;
        Lwt.return_unit
  in
  process_messages ()
