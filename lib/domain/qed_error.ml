type t =
  (* authentication errors *)
  | InvalidUsername
  | InvalidPassword
  | InvalidEmail
  | InvalidToken
  | InvalidCharacter
  | UserNotFound
  | UsernameTaken
  | EmailTaken
  (* area errors *)
  | AreaNotFound
  (* character errors *)
  | CharacterNotFound
  | NameTaken
  (* communication errors *)
  | InvalidMessageType
  | InvalidSenderId
  | InvalidContent
  | InvalidAreaId
  (* database errors *)
  | DatabaseError of string
  (* network errors *)
  | NetworkError of string
  (* server errors *)
  | ServerError of string
  (* unknown errors *)
  | UnknownError of string
[@@deriving yojson]

let to_string = function
  | InvalidUsername    -> "Invalid username"
  | InvalidPassword    -> "Invalid password"
  | InvalidEmail       -> "Invalid email"
  | InvalidToken       -> "Invalid token"
  | InvalidCharacter   -> "Invalid character"
  | UserNotFound       -> "User not found"
  | UsernameTaken      -> "Username taken"
  | EmailTaken         -> "Email taken"
  | AreaNotFound       -> "Area not found"
  | CharacterNotFound  -> "Character not found"
  | NameTaken          -> "Name taken"
  | InvalidMessageType -> "Invalid message type"
  | InvalidSenderId    -> "Invalid sender ID"
  | InvalidContent     -> "Invalid content"
  | InvalidAreaId      -> "Invalid area ID"
  | DatabaseError s    -> "Database error: " ^ s
  | NetworkError s     -> "Network error: " ^ s
  | ServerError s      -> "Server error: " ^ s
  | UnknownError s     -> "Unknown error: " ^ s