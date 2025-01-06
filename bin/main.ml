open Base
open Protocol.Message

module Client = struct
  type t = {
    id : string;
    send : string -> unit Lwt.t;
    mutable user_id : string option;
    mutable character_id : string option;
  }
end

module GameState = struct
  type t = {
    clients : (string, Client.t) Hashtbl.t;
    db : (module Caqti_lwt.CONNECTION);
  }

  let create db = { clients = Hashtbl.create (module String); db }

  let add_client t client_id client =
    Hashtbl.set t.clients ~key:client_id ~data:client

  let remove_client t client_id = Hashtbl.remove t.clients client_id

  let _broadcast t message =
    Hashtbl.iter t.clients ~f:(fun client ->
        Lwt.async (fun () -> client.Client.send message))
end

let game_tick _state =
  let open Lwt.Syntax in
  let* () = Lwt_unix.sleep 1.0 in
  (* ignore (Stdio.print_endline "Tick"); *)
  (* Update game state, NPCs, etc *)
  Lwt.return_unit

let rec game_loop state =
  let open Lwt.Syntax in
  let* () = game_tick state in
  game_loop state

let handle_client_message state client message =
  let db = state.GameState.db in
  match message with
  | Register { username; password; email } -> (
      let%lwt result = Model.User.register db ~email ~username ~password in
      match result with
      | Ok user ->
          client.Client.user_id <- Some user.id;
          let auth_msg =
            AuthSuccess { token = "temp_token"; user_id = user.id }
          in
          client.Client.send
            (auth_msg |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error _ ->
          client.Client.send
            (Error { message = "Registration failed" }
            |> server_message_to_yojson |> Yojson.Safe.to_string))
  | Login { username; password } -> (
      let%lwt result = Model.User.authenticate db ~username ~password in
      match result with
      | Ok user ->
          client.Client.user_id <- Some user.id;
          let auth_msg =
            AuthSuccess { token = "temp_token"; user_id = user.id }
          in
          client.Client.send
            (auth_msg |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error _ ->
          client.Client.send
            (Error { message = "Invalid credentials" }
            |> server_message_to_yojson |> Yojson.Safe.to_string))

let handle_client state client_id send_message =
  let client =
    {
      Client.id = client_id;
      send = (fun msg -> send_message msg);
      user_id = None;
      character_id = None;
    }
  in

  GameState.add_client state client_id client;

  let handle_message msg =
    match client_message_of_yojson (Yojson.Safe.from_string msg) with
    | Ok message -> handle_client_message state client message
    | Error _err ->
        client.Client.send
          (Error { message = "Invalid message format" }
          |> server_message_to_yojson |> Yojson.Safe.to_string)
  in
  handle_message

let cleanup_client state client_id = GameState.remove_client state client_id

let () =
  match Lwt_main.run (Db.connect ()) with
  | Error err ->
      Stdio.prerr_endline
        ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok db ->
      let state = GameState.create db in

      (* Start the game loop in the background *)
      Lwt.async (fun () -> game_loop state);

      (* Run the web server *)
      Dream.run ~interface:"0.0.0.0" ~port:3030
      @@ Dream.logger
      @@ Dream.router
           [
             Dream.get "/websocket" (fun _ ->
                 Dream.websocket (fun websocket ->
                     let client_id =
                       let random_data =
                         Printf.sprintf "%f-%d" (Unix.gettimeofday ())
                           (Random.int 1_000_000)
                       in
                       Digestif.SHA256.(to_hex (digest_string random_data))
                     in
                     let send_message msg = Dream.send websocket msg in
                     let handler = handle_client state client_id send_message in
                     let rec process_messages () =
                       match%lwt Dream.receive websocket with
                       | Some msg ->
                           let%lwt () = handler msg in
                           process_messages ()
                       | None ->
                           cleanup_client state client_id;
                           Lwt.return_unit
                     in
                     process_messages ()));
           ]
