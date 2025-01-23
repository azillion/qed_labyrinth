open Base
open Lwt.Syntax

let error_response ~status error =
  Dream.json ~status
    (Yojson.Safe.to_string (`Assoc [ ("error", `String error) ]))

let user_response ~token =
  Dream.json (Yojson.Safe.to_string (`Assoc [ ("token", `String token) ]))

let is_valid_username username = String.length username >= 3
let is_valid_password password = String.length password >= 6

let is_valid_email _email = true

let handle_login body =
  let open Qed_domain in
  match body with
  | `Assoc [ ("username", `String username); ("password", `String password) ]
    -> (
      let* result = User.authenticate ~username ~password in
      match result with
      | Ok user -> (
          match Jwt.generate_token user.User.id with
          | Ok token -> (
              let expires_at =
                Ptime.add_span (Ptime_clock.now ())
                  (Ptime.Span.of_int_s (24 * 60 * 60))
                |> Option.value_exn
              in
              let* token_result =
                User.update_token ~user_id:user.User.id ~token:(Some token)
                  ~expires_at:(Some expires_at)
              in
              match token_result with
              | Ok () -> user_response ~token
              | Error _ ->
                  error_response ~status:`Internal_Server_Error
                    "Failed to store token")
          | Error _ ->
              error_response ~status:`Internal_Server_Error
                "Failed to generate token")
      | Error User.UserNotFound | Error User.InvalidPassword ->
          error_response ~status:`Unauthorized "Invalid username or password"
      | Error (User.DatabaseError msg) ->
          error_response ~status:`Internal_Server_Error msg
      | Error _ ->
          error_response ~status:`Internal_Server_Error "Authentication failed")
  | e ->
      error_response ~status:`Bad_Request
        ("Invalid request format: " ^ Yojson.Safe.to_string e)

let handle_register body =
  let open Qed_domain in
  match body with
  | `Assoc
      [
        ("username", `String username);
        ("password", `String password);
        ("email", `String email);
      ] -> (
      if not (is_valid_username username) then
        error_response ~status:`Bad_Request "Invalid username"
      else if not (is_valid_password password) then
        error_response ~status:`Bad_Request "Invalid password"
      else if not (is_valid_email email) then
        error_response ~status:`Bad_Request "Invalid email"
      else
        let* register_result = User.register ~username ~password ~email in
        match register_result with
        | Ok user -> (
            match Jwt.generate_token user.id with
            | Ok token -> (
                let expires_at =
                  Ptime.add_span (Ptime_clock.now ())
                    (Ptime.Span.of_int_s (24 * 60 * 60))
                  |> Option.value_exn
                in
                let* token_result =
                  User.update_token ~user_id:user.id ~token:(Some token)
                    ~expires_at:(Some expires_at)
                in
                match token_result with
                | Ok () -> user_response ~token
                | Error _ ->
                    error_response ~status:`Internal_Server_Error
                      "Failed to store token")
            | Error _ ->
                error_response ~status:`Internal_Server_Error
                  "Token generation failed")
        | Error User.UsernameTaken ->
            error_response ~status:`Bad_Request "Username already taken"
        | Error User.EmailTaken ->
            error_response ~status:`Bad_Request "Email already taken"
        | Error (User.DatabaseError msg) ->
            error_response ~status:`Internal_Server_Error msg
        | Error _ -> error_response ~status:`Bad_Request "Registration failed")
  | _ -> error_response ~status:`Bad_Request "Invalid request format"

let handle_logout request (app_state : Qed_domain.State.t) =
  match Dream.header request "Authorization" with
  | Some auth_header when String.is_prefix auth_header ~prefix:"Bearer " -> (
      let token = String.drop_prefix auth_header 7 in
      let verify_result = Jwt.verify_token token in
      match verify_result with
      | Ok user_id -> (
          let* user_result = Qed_domain.User.find_by_id user_id in
          match user_result with
          | Ok _ ->
              let* _ =
                Qed_domain.User.update_token ~user_id ~token:None
                  ~expires_at:None
              in
              let () =
                Qed_domain.Connection_manager.remove_client
                  app_state.connection_manager user_id
              in
              Dream.json ~status:`No_Content ""
          | Error _ -> error_response ~status:`Unauthorized "User not found")
      | Error _ -> error_response ~status:`Unauthorized "Invalid token")
  | _ -> error_response ~status:`Unauthorized "No authorization token"
