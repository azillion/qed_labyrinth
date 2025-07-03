open Base
open Lwt.Syntax
module Account_system = Qed_domain.Account_system
module Components = Qed_domain.Components

let error_response ~status error =
  Dream.json ~status
    (Yojson.Safe.to_string (`Assoc [ ("error", `String error) ]))

let user_response ~token ~role =
  Dream.json (Yojson.Safe.to_string 
    (`Assoc [ 
      ("token", `String token);
      ("role", `String role)
    ]))

let is_valid_username username = String.length username >= 3
let is_valid_password password = String.length password >= 6
let is_valid_email _email = true

let handle_login body =
  let open Qed_domain in
  match body with
  | `Assoc [ ("username", `String username); ("password", `String password) ]
    -> (
      let* result = Account_system.authenticate ~username ~password in
      match result with
      | Ok (user_entity_id, role) -> (
          let user_id_str = Uuidm.to_string user_entity_id in
          match Jwt.generate_token user_id_str with
          | Ok token -> (
              let expires_at =
                Some (Unix.time () +. (24.0 *. 60.0 *. 60.0))
              in
              let* token_result =
                Account_system.update_token ~user_entity_id ~token:(Some token)
                  ~expires_at
              in
              match token_result with
              | Ok () -> user_response ~token ~role:(Components.UserProfileComponent.string_of_role role)
              | Error _ ->
                  error_response ~status:`Internal_Server_Error
                    "Failed to store token")
          | Error _ ->
              error_response ~status:`Internal_Server_Error
                "Failed to generate token")
      | Error Qed_error.UserNotFound | Error Qed_error.InvalidPassword ->
          error_response ~status:`Unauthorized "Invalid username or password"
      | Error (Qed_error.DatabaseError msg) ->
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
        let* register_result = Account_system.register ~username ~password ~email in
        match register_result with
        | Ok (user_entity_id, role) -> (
            let user_id_str = Uuidm.to_string user_entity_id in
            match Jwt.generate_token user_id_str with
            | Ok token -> (
                let expires_at =
                  Some (Unix.time () +. (24.0 *. 60.0 *. 60.0))
                in
                let* token_result =
                  Account_system.update_token ~user_entity_id ~token:(Some token)
                    ~expires_at
                in
                match token_result with
                | Ok () -> user_response ~token ~role:(Components.UserProfileComponent.string_of_role role)
                | Error _ ->
                    error_response ~status:`Internal_Server_Error
                      "Failed to store token")
            | Error _ ->
                error_response ~status:`Internal_Server_Error
                  "Token generation failed")
        | Error Qed_error.UsernameTaken ->
            error_response ~status:`Bad_Request "Username already taken"
        | Error Qed_error.EmailTaken ->
            error_response ~status:`Bad_Request "Email already taken"
        | Error (Qed_error.DatabaseError msg) ->
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
          let user_entity_id = Uuidm.of_string user_id |> Option.value_exn in
          let* token_result =
            Account_system.update_token ~user_entity_id ~token:None
              ~expires_at:None
          in
          match token_result with
          | Ok () ->
              let () =
                Qed_domain.Connection_manager.remove_client
                  app_state.connection_manager user_id
              in
              Dream.json ~status:`No_Content ""
          | Error _ -> error_response ~status:`Unauthorized "Failed to logout")
      | Error _ -> error_response ~status:`Unauthorized "Invalid token")
  | _ -> error_response ~status:`Unauthorized "No authorization token"
