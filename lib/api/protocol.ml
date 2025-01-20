type auth_message =
  | Register of { username : string; password : string; email : string }
  | Login of { username : string; password : string }
  | Verify of { token : string }
  | Logout

type client_message =
  | CreateCharacter of { name : string }
  | SelectCharacter of { character_id : string }
  | ListCharacters
[@@deriving yojson]

type error_response = {
  error: Yojson.Safe.t
} [@@deriving yojson]

let error_response_of_string str =
  let json = Yojson.Safe.from_string str in
  { error = json }

type server_message =
  | CharacterList of { characters : Types.character list }
  | CharacterListFailed of error_response
  | CharacterCreated of Yojson.Safe.t
  | CharacterCreationFailed of error_response
  | CharacterSelected of { character : Types.character }
  | Error of error_response
[@@deriving yojson]

