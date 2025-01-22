type auth_message =
  | Register of { username : string; password : string; email : string }
  | Login of { username : string; password : string }
  | Verify of { token : string }
  | Logout

type client_message =
  | CreateCharacter of { name : string }
  | SelectCharacter of { character_id : string }
  | ListCharacters
  | Command of { command : string }
  | SendChat of { message : string }
  | SendEmote of { message : string }
  | SendSystem of { message : string }
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
  | CharacterSelectionFailed of error_response
  | Area of { area : Types.area }
  | Error of error_response
  | CommandSuccess of { message : string }
  | CommandFailed of { error: string }
  | ChatHistory of { messages : string list }
  | ChatMessage of { message : Types.chat_message }
[@@deriving yojson]

