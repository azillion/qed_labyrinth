open Base
open Protocol.Message
open Game
open Qed_error

let handle_auth_message state client = function
  | Register { username; password; email } -> (
      let%lwt result = Model.User.register state.State.db ~username ~password ~email in
      match result with
      | Ok user ->
          Client.set_authenticated client user.id;
          let auth_msg =
            AuthSuccess { token = "temp_token"; user_id = user.id }
          in
          client.Client.send
            (auth_msg |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error _ ->
          client.Client.send
            (Error { message = Qed_error.auth_error_to_string RegistrationFailed }
            |> server_message_to_yojson |> Yojson.Safe.to_string))
  | Login { username; password } -> (
      let%lwt result =
        Model.User.authenticate state.State.db ~username ~password
      in
      match result with
      | Ok user ->
          Client.set_authenticated client user.id;
          let auth_msg =
            AuthSuccess { token = "temp_token"; user_id = user.id }
          in
          client.Client.send
            (auth_msg |> server_message_to_yojson |> Yojson.Safe.to_string)
      | Error _ ->
          client.Client.send
            (Error { message = Qed_error.auth_error_to_string InvalidCredentials }
            |> server_message_to_yojson |> Yojson.Safe.to_string))
