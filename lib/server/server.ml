open Base

let error_response ?(status = `Bad_Request) message =
  Dream.response
    ~code:(Dream.status_to_int status)
    (Yojson.Safe.to_string (`Assoc [ ("error", `String message) ]))

let is_valid_token request : (unit, Dream.response) Lwt_result.t =
let open Qed_domain in
  let open Lwt.Syntax in
  match Dream.query request "token" with
  | Some token -> (
      let verify_result = Jwt.verify_token token in
      match verify_result with
      | Ok user_id -> (
          let* user_result = User.find_by_id user_id in
          match user_result with
          | Ok user -> (
              let now = Ptime_clock.now () in
              match (user.token, user.token_expires_at) with
              | Some db_token, Some expires_at
                when String.equal db_token token
                     && Ptime.is_later expires_at ~than:now ->
                  Lwt.return_ok ()
              | _, None | None, _ | Some _, Some _ ->
                  Lwt.return_error
                    (error_response ~status:`Unauthorized
                       "Token invalid or expired"))
          | Error User.UserNotFound ->
              Lwt.return_error
                (error_response ~status:`Unauthorized "User not found")
          | Error _ ->
              Lwt.return_error
                (error_response ~status:`Internal_Server_Error "Database error")
          )
      | Error `TokenExpired ->
          Lwt.return_error
            (error_response ~status:`Unauthorized "Token expired")
      | Error _ ->
          Lwt.return_error
            (error_response ~status:`Unauthorized "Invalid token"))
  | None ->
      Lwt.return_error
        (error_response ~status:`Unauthorized "No authorization token")

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

let auth_middleware inner_handler request =
  let open Lwt.Syntax in
  let* auth_result = is_valid_token request in
  match auth_result with
  | Ok () -> inner_handler request
  | Error response -> Lwt.return response

let start () =
  let open Http_handlers in
  let connection_manager = Connection_manager.create () in
  let app_state = State.create ~connection_manager in
let open Qed_domain in
  (* Start game loop *)
  Lwt.async (fun () -> Loop.run ());

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
           Dream.get "/auth/logout" (fun request ->
               handle_logout request app_state);
           Dream.get "/websocket"
             (auth_middleware (fun request ->
                  let%lwt auth_result = is_valid_token request in
                  match auth_result with
                  | Ok () ->
                      Dream.websocket
                        (Websocket_handler.handler app_state.connection_manager)
                  | Error response -> Lwt.return response));
         ])
