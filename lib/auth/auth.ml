open Base

let error_to_string = function
  | `Invalid_algorithm -> "Invalid algorithm"
  | `Invalid_format -> "Invalid format"
  | `Missing_key -> "Missing key"
  | `Not_supported -> "Not supported"
  | `Invalid_signature -> "Invalid signature"
  | `Invalid_json -> "Invalid JSON"
  | `No_jwk -> "No JWK"
  | `Wrong_algorithm -> "Wrong algorithm"
  | `Invalid_key -> "Invalid key"
  | `Expired -> "Token expired"
  | `Not_json -> "Not valid JSON"
  | `Msg msg -> msg
  | _ -> "Unknown error"
(* JWT handling *)
module Jwt = struct
  let secret = "your-shared-secret-key-make-this-secure"
  
  let generate_token user_id =
    let header = Jose.Header.make_header ~typ:"JWT" (Jose.Jwk.make_oct secret) in
    let now = Ptime_clock.now () in
    let exp = Ptime.add_span now (Ptime.Span.of_int_s (60 * 60 * 24)) in (* 24 hours *)
    let payload = 
      Jose.Jwt.empty_payload
      |> Jose.Jwt.add_claim "sub" (`String user_id)
      |> Jose.Jwt.add_claim "exp" (`Int (
        match exp with
        | Some t -> Int.of_float (Ptime.to_float_s t)
        | None -> Int.of_float (Ptime.to_float_s now)
      ))
    in
    let jwt = Jose.Jwt.sign ~header ~payload (Jose.Jwk.make_oct secret) in
    match jwt with
    | Ok jwt -> Ok (Jose.Jwt.to_string jwt)
    | Error e -> Error (error_to_string e)

  let verify_token token =
    let jwk = Jose.Jwk.make_oct secret |> Jose.Jwk.pub_of_priv in
    let now = Ptime_clock.now () in
    match Jose.Jwt.of_string ~jwk ~now token with
    | Ok jwt -> 
        (match Jose.Jwt.get_string_claim jwt "sub" with
         | Some user_id -> Ok user_id
         | None -> Error "Invalid token: missing user_id")
    | Error e -> Error (error_to_string e)
end

(* Auth handlers *)
let handle_login db body =
  match body with
  | `Assoc [("username", `String username); ("password", `String password)] ->
      (match%lwt Model.User.authenticate db ~username ~password with
       | Ok user ->
           (match Jwt.generate_token user.id with
            | Ok token ->
                let response = 
                  `Assoc [
                    ("token", `String token);
                    ("user", `Assoc [
                      ("id", `String user.id);
                      ("username", `String user.username);
                      ("email", `String user.email)
                    ])
                  ]
                in
                Lwt.return (Dream.json (Yojson.Safe.to_string response))
            | Error msg ->
                Lwt.return (Dream.json ~status:`Internal_Server_Error 
                  (Yojson.Safe.to_string (`Assoc [("error", `String msg)]))))
       | Error Model.User.UserNotFound ->
           Lwt.return (Dream.json ~status:`Unauthorized
             (Yojson.Safe.to_string 
               (`Assoc [("error", `String "Invalid username or password")])))
       | Error Model.User.InvalidPassword ->
           Lwt.return (Dream.json ~status:`Unauthorized
             (Yojson.Safe.to_string 
               (`Assoc [("error", `String "Invalid username or password")])))
       | Error Model.User.UsernameTaken ->
           Lwt.return (Dream.json ~status:`Bad_Request
             (Yojson.Safe.to_string 
               (`Assoc [("error", `String "Username already taken")])))
       | Error (Model.User.DatabaseError msg) ->
           Lwt.return (Dream.json ~status:`Internal_Server_Error
             (Yojson.Safe.to_string (`Assoc [("error", `String msg)]))))
  | _ ->
      Lwt.return (Dream.json ~status:`Bad_Request 
        (Yojson.Safe.to_string 
          (`Assoc [("error", `String "Invalid request format")])))

let handle_register db body =
  match body with
  | `Assoc [
      ("username", `String username);
      ("password", `String password);
      ("email", `String email)
    ] ->
      (match%lwt Model.User.register db ~username ~password ~email with
       | Ok user ->
           (match Jwt.generate_token user.id with
            | Ok token ->
                let response = 
                  `Assoc [
                    ("token", `String token);
                    ("user", `Assoc [
                      ("id", `String user.id);
                      ("username", `String user.username);
                      ("email", `String user.email)
                    ])
                  ]
                in
                Lwt.return (Dream.json (Yojson.Safe.to_string response))
            | Error msg ->
                Lwt.return (Dream.json ~status:`Internal_Server_Error 
                  (Yojson.Safe.to_string (`Assoc [("error", `String msg)]))))
       | Error Model.User.UsernameTaken ->
           Lwt.return (Dream.json ~status:`Bad_Request 
             (Yojson.Safe.to_string 
               (`Assoc [("error", `String "Username already taken")])))
       | Error (Model.User.DatabaseError msg) ->
           Lwt.return (Dream.json ~status:`Internal_Server_Error 
             (Yojson.Safe.to_string (`Assoc [("error", `String msg)])))
       | Error Model.User.InvalidPassword ->
           Lwt.return (Dream.json ~status:`Bad_Request
             (Yojson.Safe.to_string 
               (`Assoc [("error", `String "Invalid password format")])))
       | Error _ ->
           Lwt.return (Dream.json ~status:`Bad_Request 
             (Yojson.Safe.to_string 
               (`Assoc [("error", `String "Registration failed")]))))
  | _ ->
      Lwt.return (Dream.json ~status:`Bad_Request 
        (Yojson.Safe.to_string 
          (`Assoc [("error", `String "Invalid request format")])))

let handle_verify db request =
  match Dream.header request "Authorization" with
  | Some auth_header when String.is_prefix auth_header ~prefix:"Bearer " ->
      let token = String.drop_prefix auth_header 7 in
      (match Jwt.verify_token token with
       | Ok user_id ->
           (match%lwt Model.User.find_user_by_id_view db user_id with
            | Ok (Some user) ->
                let response = 
                  `Assoc [
                    ("user", `Assoc [
                      ("id", `String user.id);
                      ("username", `String user.username);
                      ("email", `String user.email)
                    ])
                  ]
                in
                Lwt.return (Dream.json (Yojson.Safe.to_string response))
            | Ok None ->
                Lwt.return (Dream.json ~status:`Unauthorized 
                  (Yojson.Safe.to_string 
                    (`Assoc [("error", `String "User not found")])))
            | Error _ ->
                Lwt.return (Dream.json ~status:`Internal_Server_Error 
                  (Yojson.Safe.to_string 
                    (`Assoc [("error", `String "Database error")]))))
       | Error msg ->
           Lwt.return (Dream.json ~status:`Unauthorized 
             (Yojson.Safe.to_string (`Assoc [("error", `String msg)]))))
  | _ ->
      Lwt.return (Dream.json ~status:`Unauthorized 
        (Yojson.Safe.to_string 
          (`Assoc [("error", `String "No authorization token")])))
