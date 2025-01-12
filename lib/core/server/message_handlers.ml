open Qed_labyrinth_core
open Game
open Model.User

let auth_error_to_string = function
  | Model.User.UserNotFound -> "User not found"
  | InvalidPassword -> "Invalid password"
  | Model.User.EmailTaken -> "Email already taken"
  | UsernameTaken -> "Username already taken"
  | DatabaseError _msg -> "Database error occurred"

let handle_message (_state : State.t) (_client : Client.t) (message : Protocol.client_message) =
  match message with
  | CreateCharacter { name = _ } -> Lwt.return_unit