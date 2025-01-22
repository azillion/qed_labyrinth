  type message_type =
  | Chat
  | Emote
  | System
[@@deriving yojson]

type t = {
  id : string;
  message_type : message_type;
  sender_id : string option;
  content : string;
  area_id : string option;
  timestamp : float;
}

type error =
  | InvalidMessageType
  | InvalidSenderId
  | InvalidContent
  | InvalidAreaId
  | DatabaseError of string

val create :
  message_type:message_type ->
  sender_id:string option ->
  content:string ->
  area_id:string option ->
  (t, error) result Lwt.t

val find_by_area_id :
  string ->
  (t list, error) result Lwt.t
