(* Protocol defines the messages that can be sent between the client and the server *)
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
  | Move of { direction : Components.ExitComponent.direction }
  | RequestAdminMap
  | RequestWorldGeneration
  | RequestWorldDeletion
  | RequestStatusFrame
  | Help
  | Unknown of string
[@@deriving yojson]

let parse_command command =
  match command with
  | "/n" | "/north" -> Move { direction = Components.ExitComponent.North }
  | "/s" | "/south" -> Move { direction = Components.ExitComponent.South }
  | "/e" | "/east" -> Move { direction = Components.ExitComponent.East }
  | "/w" | "/west" -> Move { direction = Components.ExitComponent.West }
  | "/u" | "/up" -> Move { direction = Components.ExitComponent.Up }
  | "/d" | "/down" -> Move { direction = Components.ExitComponent.Down }
  | "/world generate" -> RequestWorldGeneration
  | "/world delete" -> RequestWorldDeletion
  | "/help" -> Help
  | _ -> Unknown command

type error_response = { error : Yojson.Safe.t } [@@deriving yojson]

let error_response_of_string str =
  let json = Yojson.Safe.from_string str in
  { error = json }

type server_message =
  | CharacterList of Types.characters_list
  | CharacterListFailed of error_response
  | CharacterCreated of { character : Types.list_character }
  | CharacterCreationFailed of error_response
  | CharacterSelected of { character : Types.character }
  | CharacterSelectionFailed of error_response
  | Area of { area : Types.area }
  | Status of { status : Types.status }
  | Error of error_response
  | CommandSuccess of { message : Types.chat_message }
  | CommandFailed of { error : string }
  | ChatHistory of { messages : Types.chat_message list }
  | ChatMessage of { message : Types.chat_message }
  | AdminMap of { world : Types.world }
  | UserRole of { role : string }
[@@deriving yojson]
