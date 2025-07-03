type core_attributes = {
  might : int;
  finesse : int;
  wits : int;
  grit : int;
  presence : int;
} [@@deriving yojson]

type derived_stats = {
  physical_power : int;
  spell_power : int;
  accuracy : int;
  evasion : int;
  armor : int;
  resolve : int;
} [@@deriving yojson]

type character_sheet = {
  id : string;
  name : string;
  health : int;
  max_health : int;
  action_points : int;
  max_action_points : int;
  core_attributes : core_attributes;
  derived_stats : derived_stats;
} [@@deriving yojson]

type list_character = {
  id : string;
  name : string;
} [@@deriving yojson]

type characters_list = {
  characters : list_character list;
} [@@deriving yojson]

type coordinate = {
  x : int;
  y : int;
  z : int;
} [@@deriving yojson]

type exit = {
  direction : string;
} [@@deriving yojson]

type area = {
  id : string;
  name : string;
  description : string;
  coordinate : coordinate option;
  exits : exit list;
  elevation : float option;
  temperature : float option;
  moisture : float option;
} [@@deriving yojson]

let exit_of_model (exit_model : Area.exit) : exit =
  {
    direction = Area.direction_to_string exit_model.direction;
  }

let area_of_model (area_model : Area.t) (exits : Area.exit list) : area =
  {
    id = area_model.id;
    name = area_model.name;
    description = area_model.description;
    coordinate = Some { x = area_model.x; y = area_model.y; z = area_model.z };
    exits = List.map exit_of_model exits;
    elevation = area_model.elevation;
    temperature = area_model.temperature;
    moisture = area_model.moisture;
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

type connection = {
  from : coordinate;
  to_ : coordinate;  (* using to_ since 'to' is a keyword in OCaml *)
} [@@deriving yojson]

type world = {
  rooms : area list;
  connections : connection list;
  current_location : string;
} [@@deriving yojson]

type status = {
  health : int;
  mana : int;
  level : int;
  experience : int;
  time_of_day : string;
} [@@deriving yojson]
