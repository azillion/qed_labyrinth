open Base
open Protocol.Message
open Game
open Model.User

let auth_error_to_string = function
  | Model.User.UserNotFound -> "User not found"
  | InvalidPassword -> "Invalid password"
  | UsernameTaken -> "Username already taken"
  | DatabaseError _msg -> "Database error occurred"

let handle_message state client message =
  let send_error msg =
    client.Client.send
      (Error { message = msg }
      |> server_message_to_yojson |> Yojson.Safe.to_string)
  in
  match message with
  | Register { username; password; email } -> (
      match%lwt
        State.with_db state (fun db ->
            Model.User.register db ~username ~password ~email)
      with
      | Ok user ->
          Client.set_authenticated client user.id;
          client.Client.send
            (AuthSuccess { token = "temp_token"; user_id = user.id }
            |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error err -> send_error (auth_error_to_string err))
  | Login { username; password } -> (
      match%lwt
        State.with_db state (fun db ->
            Model.User.authenticate db ~username ~password)
      with
      | Ok user ->
          Client.set_authenticated client user.id;
          client.Client.send
            (AuthSuccess { token = "temp_token"; user_id = user.id }
            |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error err -> send_error (auth_error_to_string err))
