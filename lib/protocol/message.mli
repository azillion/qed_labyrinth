(* Frame type representing different UI components *)
type frame_id = AreaDescription | Navigation | ActionLog | PlayerList
[@@deriving yojson]

(* Core update type for a single UI frame *)
type frame_update = {
  frame_id : frame_id;
  content : Yojson.Safe.t;
  mode : [ `Replace | `Append ];
}
[@@deriving yojson]

(* Messages that can be sent from client to server *)
type client_message =
  | Command of { command_type : string; args : Yojson.Safe.t }
  | Subscribe of { frames : frame_id list }
[@@deriving yojson]

(* Messages that can be sent from server to client *)
type server_message = StateUpdate of frame_update list | Error of string
[@@deriving yojson]

(* Conversion functions *)
val client_message_of_string : string -> (client_message, string) result
val server_message_to_string : server_message -> string
