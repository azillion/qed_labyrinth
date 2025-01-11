open Base
open Lwt.Syntax

let error_response ~status error = 
  Dream.json ~status
    (Yojson.Safe.to_string 
      (`Assoc [("error", `String error)]))

let user_response ~token user =
  Dream.json (Yojson.Safe.to_string
    (`Assoc [
      ("token", `String token);
      ("user", `Assoc [
        ("id", `String user.Model.User.t.id);
        ("username", `String user.Model.User.t.username);
        ("email", `String user.Model.User.t.email);
      ])
    ]))

let handle_login (module Db : Caqti_lwt.CONNECTION) body =
  match body with
  | `Assoc [("username", `String username); ("password", `String password)] ->
      let module M = Model.Make(Db) in
      let module A = Auth.Make(Db) in
      let* auth_result = A.authenticate_user ~username ~password in
      (match auth_result with
      | Ok token ->
          let* user_result = M.User.find_by_username username in
          (match user_result with
          | Ok (Some user) -> Lwt.return (user_response ~token user)
          | _ -> Lwt.return (error_response ~status:`Internal_Server_Error "Failed to retrieve user"))
      | Error `UserNotFound | Error `InvalidPassword ->
          Lwt.return (error_response ~status:`Unauthorized "Invalid username or password")
      | Error `DatabaseError msg ->
          Lwt.return (error_response ~status:`Internal_Server_Error msg)
      | Error _ -> 
          Lwt.return (error_response ~status:`Internal_Server_Error "Authentication failed"))
  | _ -> Lwt.return (error_response ~status:`Bad_Request "Invalid request format")

let handle_register (module Db : Caqti_lwt.CONNECTION) body =
  match body with
  | `Assoc [
      ("username", `String username);
      ("password", `String password);
      ("email", `String email)
    ] ->
      let module M = Model.Make(Db) in
      let module A = Auth.Make(Db) in
      let* register_result = M.User.register ~username ~password ~email in
      (match register_result with
      | Ok user ->
          let* token_result = A.authenticate_user ~username ~password in
          (match token_result with
          | Ok token -> Lwt.return (user_response ~token user)
          | Error _ -> Lwt.return (error_response ~status:`Internal_Server_Error "Token generation failed"))
      | Error M.User.UsernameTaken ->
          Lwt.return (error_response ~status:`Bad_Request "Username already taken")
      | Error M.User.EmailTaken ->
          Lwt.return (error_response ~status:`Bad_Request "Email already taken")
      | Error (M.User.DatabaseError msg) ->
          Lwt.return (error_response ~status:`Internal_Server_Error msg)
      | Error _ ->
          Lwt.return (error_response ~status:`Bad_Request "Registration failed"))
  | _ -> Lwt.return (error_response ~status:`Bad_Request "Invalid request format")

let handle_verify (module Db : Caqti_lwt.CONNECTION) request =
  match Dream.header request "Authorization" with
  | Some auth_header when String.is_prefix auth_header ~prefix:"Bearer " ->
      let module M = Model.Make(Db) in
      let module A = Auth.Make(Db) in
      let token = String.drop_prefix auth_header 7 in
      match A.verify_token token with
      | Ok user_id ->
          let* user_result = M.User.find_by_id user_id in
          (match user_result with
          | Ok (Some user) -> Lwt.return (user_response ~token user)
          | Ok None -> Lwt.return (error_response ~status:`Unauthorized "User not found")
          | Error _ -> Lwt.return (error_response ~status:`Internal_Server_Error "Database error"))
      | Error `TokenExpired -> Lwt.return (error_response ~status:`Unauthorized "Token expired")
      | Error _ -> Lwt.return (error_response ~status:`Unauthorized "Invalid token")
  | Some _ -> Lwt.return (error_response ~status:`Unauthorized "Invalid authorization header")
  | None -> Lwt.return (error_response ~status:`Unauthorized "No authorization token")