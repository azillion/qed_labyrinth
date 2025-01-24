type character = {
  id : string;
  name : string;
} [@@deriving yojson]

val character_of_model : Character.t -> character

type exit = {
  direction : string;
} [@@deriving yojson]

val exit_of_model : Area.exit -> exit

type area = {
  name : string;
  description : string;
  exits : exit list;
} [@@deriving yojson]

val area_of_model : Area.t -> Area.exit list -> area

type chat_message = {
  sender_id : string option;
  message_type : Communication.message_type;
  content : string;
  timestamp : float;
  area_id : string option;
} [@@deriving yojson]

val chat_message_of_model : Communication.t -> chat_message
