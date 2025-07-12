type t =
  (* authentication errors *)
  | InvalidPassword
  | InvalidEmail
  | InvalidToken
  | InvalidCharacter
  | UserNotFound
  | EmailTaken
  (* area errors *)
  | AreaNotFound
  (* character errors *)
  | CharacterNotFound
  | NameTaken
  (* logic errors *)
  | LogicError of string
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
  | InvalidPassword    -> "Invalid password"
  | InvalidEmail       -> "Invalid email"
  | InvalidToken       -> "Invalid token"
  | InvalidCharacter   -> "Invalid character"
  | UserNotFound       -> "User not found"
  | EmailTaken         -> "Email taken"
  | AreaNotFound       -> "Area not found"
  | CharacterNotFound  -> "Character not found"
  | NameTaken          -> "Name taken"
  | LogicError s       -> "Logic error: " ^ s
  | InvalidMessageType -> "Invalid message type"
  | InvalidSenderId    -> "Invalid sender ID"
  | InvalidContent     -> "Invalid content"
  | InvalidAreaId      -> "Invalid area ID"
  | DatabaseError s    -> "Database error: " ^ s
  | NetworkError s     -> "Network error: " ^ s
  | ServerError s      -> "Server error: " ^ s
  | UnknownError s     -> "Unknown error: " ^ s