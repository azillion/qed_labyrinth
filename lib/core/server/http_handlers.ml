open Base
open Lwt.Syntax
open Qed_labyrinth_core

let error_response ~status error =
  Dream.json ~status
    (Yojson.Safe.to_string (`Assoc [ ("error", `String error) ]))

let user_response ~token =
  Dream.json (Yojson.Safe.to_string (`Assoc [ ("token", `String token) ]))

(* let is_valid_username username = String.length username >= 3 *)
(* let is_valid_password password = String.length password >= 8 *)

(* let is_valid_email email = *)
(*   let email_regex = *)
(*     Str.regexp "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$" *)
(*   in *)
(*   Str.string_match email_regex email 0 *)

let handle_login body =
  match body with
  | `Assoc [ ("username", `String username); ("password", `String password) ]
    -> (
      let* result = Model.User.authenticate ~username ~password in
      match result with
      | Ok user -> (
          match Jwt.generate_token user.Model.User.id with
          | Ok token -> (
              let expires_at =
                Ptime.add_span (Ptime_clock.now ())
                  (Ptime.Span.of_int_s (24 * 60 * 60))
                |> Option.value_exn
              in
              let* token_result =
                Model.User.update_token ~user_id:user.Model.User.id
                  ~token:(Some token) ~expires_at:(Some expires_at)
              in
              match token_result with
              | Ok () -> user_response ~token
              | Error _ ->
                  error_response ~status:`Internal_Server_Error
                    "Failed to store token")
          | Error _ ->
              error_response ~status:`Internal_Server_Error
                "Failed to generate token")
      | Error Model.User.UserNotFound | Error Model.User.InvalidPassword ->
          error_response ~status:`Unauthorized "Invalid username or password"
      | Error (Model.User.DatabaseError msg) ->
          error_response ~status:`Internal_Server_Error msg
      | Error _ ->
          error_response ~status:`Internal_Server_Error "Authentication failed")
  | e ->
      error_response ~status:`Bad_Request
        ("Invalid request format: " ^ Yojson.Safe.to_string e)

let handle_register body =
  match body with
  | `Assoc
      [
        ("username", `String username);
        ("password", `String password);
        ("email", `String email);
      ] -> (
      let* register_result = Model.User.register ~username ~password ~email in
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
                Model.User.update_token ~user_id:user.id ~token:(Some token)
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
      | Error Model.User.UsernameTaken ->
          error_response ~status:`Bad_Request "Username already taken"
      | Error Model.User.EmailTaken ->
          error_response ~status:`Bad_Request "Email already taken"
      | Error (Model.User.DatabaseError msg) ->
          error_response ~status:`Internal_Server_Error msg
      | Error _ -> error_response ~status:`Bad_Request "Registration failed")
  | _ -> error_response ~status:`Bad_Request "Invalid request format"

let handle_logout request (app_state : State.t) =
  match Dream.header request "Authorization" with
  | Some auth_header when String.is_prefix auth_header ~prefix:"Bearer " -> (
      let token = String.drop_prefix auth_header 7 in
      let verify_result = Jwt.verify_token token in
      match verify_result with
      | Ok user_id -> (
          let* user_result = Model.User.find_by_id user_id in
          match user_result with
          | Ok _ ->
              let* _ =
                Model.User.update_token ~user_id ~token:None ~expires_at:None
              in
              let () =
                Connection_manager.remove_client app_state.connection_manager
                  user_id
              in
              Dream.json ~status:`No_Content ""
          | Error _ -> error_response ~status:`Unauthorized "User not found")
      | Error _ -> error_response ~status:`Unauthorized "Invalid token")
  | _ -> error_response ~status:`Unauthorized "No authorization token"
