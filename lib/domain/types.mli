type character = {
  id : string;
  name : string;
  location_id : string;
  health : int;
  max_health : int;
  mana : int;
  max_mana : int;
  level : int;
  experience : int;
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

val exit_of_model : Area.exit -> exit

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

val area_of_model : Area.t -> Area.exit list -> area

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
