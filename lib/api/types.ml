type character = {
  id : string;
  name : string;
} [@@deriving yojson]

let character_of_model (character_model : Qed_domain.Character.t) : character =
  {
    id = character_model.id;
    name = character_model.name;
  }

type exit = {
  direction : string;
} [@@deriving yojson]

type area = {
  name : string;
  description : string;
  exits : exit list;
} [@@deriving yojson]

let exit_of_model (exit_model : Qed_domain.Area.exit) : exit =
  {
    direction = Qed_domain.Area.direction_to_string exit_model.direction;
  }

let area_of_model (area_model : Qed_domain.Area.t) (exits : Qed_domain.Area.exit list) : area =
  {
    name = area_model.name;
    description = area_model.description;
    exits = List.map exit_of_model exits;
  }

type command =
  | Move of { direction : Qed_domain.Area.direction }
  | Help
  | Unknown of string
[@@deriving yojson]

let parse_command command =
  match command with
  | "/n" | "/north" -> Move { direction = Qed_domain.Area.North }
  | "/s" | "/south" -> Move { direction = Qed_domain.Area.South }
  | "/e" | "/east" -> Move { direction = Qed_domain.Area.East }
  | "/w" | "/west" -> Move { direction = Qed_domain.Area.West }
  | "/u" | "/up" -> Move { direction = Qed_domain.Area.Up }
  | "/d" | "/down" -> Move { direction = Qed_domain.Area.Down }
  | "/help" -> Help
  | _ -> Unknown command

type chat_message = {
  sender_id : string option;
  message_type : Qed_domain.Communication.message_type;
  content : string;
  timestamp : float;
  area_id : string option;
} [@@deriving yojson]

let chat_message_of_model (message_model : Qed_domain.Communication.t) : chat_message =
  {
    sender_id = message_model.sender_id;
    message_type = message_model.message_type;
    content = message_model.content;
    timestamp = Ptime.to_float_s message_model.timestamp;
    area_id = message_model.area_id;
  }
