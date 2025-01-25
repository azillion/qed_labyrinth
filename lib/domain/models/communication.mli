type message_type = Chat | Emote | System | CommandSuccess | CommandFailed [@@deriving yojson]

type t = {
  id : string;
  message_type : message_type;
  sender_id : string option;
  content : string;
  area_id : string option;
  timestamp : Ptime.t;
}

type error =
  | InvalidMessageType
  | InvalidSenderId
  | InvalidContent
  | InvalidAreaId
  | DatabaseError of string
[@@deriving yojson]

val create :
  message_type:message_type ->
  sender_id:string option ->
  content:string ->
  area_id:string option ->
  (t, error) result Lwt.t

val find_by_area_id : string -> (t list, error) result Lwt.t
