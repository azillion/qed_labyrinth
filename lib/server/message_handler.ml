open Base
open Protocol.Message
open Game
open Model.User

let auth_error_to_string = function
  | Model.User.UserNotFound -> "User not found"
  | InvalidPassword -> "Invalid password"
  | UsernameTaken -> "Username already taken"
  | DatabaseError _msg -> "Database error occurred"

let handle_auth_message state client = function
  | Register { username; password; email } -> (
      match%lwt
        State.with_db state (fun db ->
            Model.User.register db ~username ~password ~email)
      with
      | Ok user ->
          Client.set_authenticated client user.id;
          let auth_msg =
            AuthSuccess { token = "temp_token"; user_id = user.id }
          in
          client.Client.send
            (auth_msg |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error err ->
          let msg =
            match err with
            | UserNotFound -> "User not found"
            | InvalidPassword -> "Invalid password"
            | UsernameTaken -> "Username already taken"
            | DatabaseError _ -> "A database error occurred"
          in
          client.Client.send
            (Error { message = msg }
            |> server_message_to_yojson |> Yojson.Safe.to_string))
  | Login { username; password } -> (
      match%lwt
        State.with_db state (fun db ->
            Model.User.authenticate db ~username ~password)
      with
      | Ok user ->
          Client.set_authenticated client user.id;
          let auth_msg =
            AuthSuccess { token = "temp_token"; user_id = user.id }
          in
          client.Client.send
            (auth_msg |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error err ->
          let msg =
            match err with
            | UserNotFound -> "User not found"
            | InvalidPassword -> "Invalid password"
            | UsernameTaken ->
                "Username already taken" (* Shouldn't happen for login *)
            | DatabaseError _ -> "A database error occurred"
          in
          client.Client.send
            (Error { message = msg }
            |> server_message_to_yojson |> Yojson.Safe.to_string))
