open Base
open Qed_labyrinth_core
open Model.User

let auth_error_to_string = function
  | Model.User.UserNotFound -> "User not found"
  | InvalidPassword -> "Invalid password"
  | Model.User.EmailTaken -> "Email already taken"
  | UsernameTaken -> "Username already taken"
  | DatabaseError msg -> "Database error occurred" ^ msg

let handler state websocket =
  let client_id =
    Digestif.SHA256.(
      digest_string (Int64.of_int (Random.bits ()) |> Int64.to_string) |> to_hex)
  in
  let send_message msg = Dream.send websocket msg in
  let client = Client.create client_id send_message in

  Connection_manager.add_client state client;

  let rec process_messages () =
    match%lwt Dream.receive websocket with
    | Some msg -> (
        let open Protocol in
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
            (* let%lwt () =
              client.send
                (Protocol.Message.Error
                   {
                     message =
                       Qed_error.auth_error_to_string InvalidMessageFormat;
                   }
                |> Protocol.Message.server_message_to_yojson
                |> Yojson.Safe.to_string)
            in *)
            process_messages ())
    | None ->
        Connection_manager.remove_client state client_id;
        Lwt.return_unit
  in
  process_messages ()
