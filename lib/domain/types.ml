type character = {
  id : string;
  name : string;
} [@@deriving yojson]

let character_of_model (character_model : Character.t) : character =
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

let exit_of_model (exit_model : Area.exit) : exit =
  {
    direction = Area.direction_to_string exit_model.direction;
  }

let area_of_model (area_model : Area.t) (exits : Area.exit list) : area =
  {
    name = area_model.name;
    description = area_model.description;
    exits = List.map exit_of_model exits;
  }

type chat_message = {
  sender_id : string option;
  message_type : Communication.message_type;
  content : string;
  timestamp : float;
  area_id : string option;
} [@@deriving yojson]

let chat_message_of_model (message_model : Communication.t) : chat_message =
  {
    sender_id = message_model.sender_id;
    message_type = message_model.message_type;
    content = message_model.content;
    timestamp = Ptime.to_float_s message_model.timestamp;
    area_id = message_model.area_id;
  }

type coordinate = {
  x : float;
  y : float;
  z : float;
} [@@deriving yojson]

type connection = {
  from : coordinate;
  to_ : coordinate;  (* using to_ since 'to' is a keyword in OCaml *)
} [@@deriving yojson]

type world = {
  rooms : area list;
  connections : connection list;
  current_location : string;
} [@@deriving yojson]
