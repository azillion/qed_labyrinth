(* lib/protocol/message.ml *)
type character = { id : string; name : string; location_id : string }
[@@deriving yojson]

type client_message =
  | Register of { username : string; password : string; email : string }
  | Login of { username : string; password : string }
[@@deriving yojson]

type server_message =
  | AuthSuccess of { token : string; user_id : string }
  | CharacterList of { characters : character list }
  | CharacterCreated of { character : character }
  | CharacterSelected of { character : character }
  | Error of { message : string }
[@@deriving yojson]
