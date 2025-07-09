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

(* area types *)
type coordinate = {
  x : int;
  y : int;
  z : int;
} [@@deriving yojson]

type exit = {
  direction : string;
} [@@deriving yojson]

val exit_of_model : Exit.t -> exit

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

val area_of_model : Area.t -> Exit.t list -> area

(* chat types *)
type chat_message = {
  sender_id : string option;
  message_type : Communication.message_type;
  content : string;
  timestamp : float;
  area_id : string option;
} [@@deriving yojson]

val chat_message_of_model : Communication.t -> chat_message

(* map types *)
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
