open Base

let cors_middleware inner_handler request =
  match Dream.method_ request with
  | `OPTIONS ->
      Dream.respond
        ~headers:
          [
            ("Access-Control-Allow-Origin", "*");
            ("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
            ("Access-Control-Allow-Headers", "Content-Type, Authorization");
          ]
        ""
  | _ ->
      let%lwt response = inner_handler request in
      Dream.add_header response "Access-Control-Allow-Origin" "*";
      Lwt.return response

let start () =
  let open Http_handlers in
  let connection_manager = Connection_manager.create () in
  let app_state = State.create ~connection_manager in
  (* Start game loop *)
  Lwt.async (fun () -> Game.Loop.run ());

  (* Configure web server *)
  Lwt.return
    (Dream.run ~interface:"0.0.0.0" ~port:3030
    @@ Dream.logger @@ cors_middleware
    @@ Dream.router
         [
           Dream.options "/auth/**" (fun _ ->
               Dream.respond
                 ~headers:
                   [
                     ("Access-Control-Allow-Origin", "*");
                     ("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
                     ( "Access-Control-Allow-Headers",
                       "Content-Type, Authorization" );
                   ]
                 "");
           Dream.post "/auth/login" (fun request ->
               let%lwt body = Dream.body request in
               match Yojson.Safe.from_string body with
               | exception _ ->
                   Dream.json ~status:`Bad_Request
                     (Yojson.Safe.to_string
                        (`Assoc [ ("error", `String "Invalid JSON") ]))
               | body_json -> handle_login body_json);
           Dream.post "/auth/register" (fun request ->
               let%lwt body = Dream.body request in
               match Yojson.Safe.from_string body with
               | exception _ ->
                   Dream.json ~status:`Bad_Request
                     (Yojson.Safe.to_string
                        (`Assoc [ ("error", `String "Invalid JSON") ]))
               | body_json -> handle_register body_json);
           Dream.get "/auth/verify" (fun request -> handle_verify request);
           Dream.get "/auth/logout" (fun request -> handle_logout request app_state);
           Dream.get "/websocket" (fun _ ->
               Dream.websocket
                 (Websocket_handler.handler app_state.connection_manager));
         ])
