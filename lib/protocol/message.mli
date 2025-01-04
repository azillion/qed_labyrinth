(* Content type representing different message types *)
type content_type = AreaDescription | Characters | CommandList
[@@deriving yojson]

(* Core update type for a single message *)
type content_update = {
  content_type : content_type;
  content : Yojson.Safe.t;
}
[@@deriving yojson]

type command_content = {
  command : string;
  args : Yojson.Safe.t;
}
[@@deriving yojson]

(* Messages that can be sent from client to server *)
type client_message =
  | Command of { content : command_content }
  | Subscribe of { content_types : content_type list }
  | Unsubscribe of { content_types : content_type list }
[@@deriving yojson]

(* Messages that can be sent from server to client *)
type server_message = StateUpdate of content_update list | Error of string
[@@deriving yojson]

(* Conversion functions *)
val client_message_of_string : string -> (client_message, string) result
val server_message_to_string : server_message -> string
