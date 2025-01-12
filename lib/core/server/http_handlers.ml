open Base
open Lwt.Syntax
open Qed_labyrinth_core

let error_response ~status error = 
  Dream.json ~status
    (Yojson.Safe.to_string 
      (`Assoc [("error", `String error)]))

let user_response ~token (user : Model.User.t) =
  Dream.json (Yojson.Safe.to_string
    (`Assoc [
      ("token", `String token);
      ("user", `Assoc [
        ("id", `String user.id);
        ("username", `String user.username);
        ("email", `String user.email)
      ])
    ]))

let handle_login db body =
  match body with
  | `Assoc [("username", `String username); ("password", `String password)] ->
      let* result = Model.User.authenticate ~db ~username ~password in
      (match result with
      | Ok user ->
          (match Jwt.generate_token user.Model.User.id with
          | Ok token -> (
              let* user = Model.User.find_by_username ~db username in
              (match user with
              | Ok (Some user) -> user_response ~token user
              | _ -> error_response ~status:`Internal_Server_Error "Failed to retrieve user"))
          | Error _ -> error_response ~status:`Internal_Server_Error "Failed to generate token")
      | Error Model.User.UserNotFound | Error Model.User.InvalidPassword ->
          error_response ~status:`Unauthorized "Invalid username or password"
      | Error (Model.User.DatabaseError msg) ->
          error_response ~status:`Internal_Server_Error msg
      | Error _ -> 
          error_response ~status:`Internal_Server_Error "Authentication failed")
  | _ -> error_response ~status:`Bad_Request "Invalid request format"

let handle_register db body =
  match body with
  | `Assoc [
      ("username", `String username);
      ("password", `String password);
      ("email", `String email)
    ] ->
      let* register_result = Model.User.register ~db ~username ~password ~email in
      (match register_result with
      | Ok user ->
          (match Jwt.generate_token user.id with
          | Ok token -> user_response ~token user
          | Error _ -> error_response ~status:`Internal_Server_Error "Token generation failed")
      | Error Model.User.UsernameTaken ->
          error_response ~status:`Bad_Request "Username already taken"
      | Error Model.User.EmailTaken ->
          error_response ~status:`Bad_Request "Email already taken"
      | Error (Model.User.DatabaseError msg) ->
          error_response ~status:`Internal_Server_Error msg
      | Error _ ->
          error_response ~status:`Bad_Request "Registration failed")
  | _ -> error_response ~status:`Bad_Request "Invalid request format"

let handle_verify db request =
  match Dream.header request "Authorization" with
  | Some auth_header when String.is_prefix auth_header ~prefix:"Bearer " ->
      let token = String.drop_prefix auth_header 7 in
      let verify_result = Jwt.verify_token token in
      (match verify_result with
      | Ok user_id ->
          let* user_result = Model.User.find_by_id ~db user_id in
          (match user_result with
          | Ok (Some user) -> user_response ~token user
          | Ok None -> error_response ~status:`Unauthorized "User not found"
          | Error _ -> error_response ~status:`Internal_Server_Error "Database error")
      | Error `TokenExpired -> error_response ~status:`Unauthorized "Token expired"
      | Error _ -> error_response ~status:`Unauthorized "Invalid token")
  | _ -> error_response ~status:`Unauthorized "No authorization token"