type auth_message =
  | Register of { username : string; password : string; email : string }
  | Login of { username : string; password : string }
  | Verify of { token : string }
  | Logout

type client_message =
  | CreateCharacter of { name : string }
  | SelectCharacter of { character_id : string }
  | ListCharacters
  | SendChat of { message : string }
  | SendEmote of { message : string }
  | SendSystem of { message : string }
  | RequestChatHistory
  | Command of { command : string }
  | Move of { direction : Area.direction }
  | RequestAdminMap
  | RequestWorldGeneration
  | Help
  | Unknown of string
[@@deriving yojson]

let parse_command command =
  match command with
  | "/n" | "/north" -> Move { direction = Area.North }
  | "/s" | "/south" -> Move { direction = Area.South }
  | "/e" | "/east" -> Move { direction = Area.East }
  | "/w" | "/west" -> Move { direction = Area.West }
  | "/u" | "/up" -> Move { direction = Area.Up }
  | "/d" | "/down" -> Move { direction = Area.Down }
  | "/world generate" -> RequestWorldGeneration
  | "/help" -> Help
  | _ -> Unknown command

type error_response = { error : Yojson.Safe.t } [@@deriving yojson]

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
  | CommandSuccess of { message : Types.chat_message }
  | CommandFailed of { error : string }
  | ChatHistory of { messages : Types.chat_message list }
  | ChatMessage of { message : Types.chat_message }
  | AdminMap of { world : Types.world }
[@@deriving yojson]
