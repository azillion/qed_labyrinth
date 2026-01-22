type message_type = Chat | Emote | System | CommandSuccess | CommandFailed [@@deriving yojson]

type t = {
  id : string;
  message_type : message_type;
  sender_id : string option;
  content : string;
  area_id : string option;
  timestamp : Ptime.t;
}


val create :
  message_type:message_type ->
  sender_id:string option ->
  content:string ->
  area_id:string option ->
  (t, Qed_error.t) result Lwt.t

val find_by_area_id : string -> (t list, Qed_error.t) result Lwt.t
