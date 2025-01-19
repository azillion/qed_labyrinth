open Qed_domain

let auth_error_to_string = function
  | User.UserNotFound -> "User not found"
  | InvalidPassword -> "Invalid password"
  | User.EmailTaken -> "Email already taken"
  | UsernameTaken -> "Username already taken"
  | DatabaseError _msg -> "Database error occurred"

let handle_message (_state : State.t) (_client : Client.t)
    (message : Api.Protocol.client_message) =
  match message with
  | CreateCharacter { name = _ } -> Lwt.return_unit
  | SelectCharacter { character_id = _ } -> Lwt.return_unit
