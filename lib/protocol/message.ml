type frame_id = AreaDescription | Navigation | ActionLog | PlayerList
[@@deriving yojson]

type frame_update = {
  frame_id : frame_id;
  content : Yojson.Safe.t;
  mode : [ `Replace | `Append ];
}
[@@deriving yojson]

type client_message =
  | Command of { command_type : string; args : Yojson.Safe.t }
  | Subscribe of { frames : frame_id list }
[@@deriving yojson]

type server_message = StateUpdate of frame_update list | Error of string
[@@deriving yojson]

let client_message_of_string s =
  try
    match client_message_of_yojson (Yojson.Safe.from_string s) with
    | Ok msg -> Ok msg
    | Error err -> Error ("JSON decode error: " ^ err)
  with
  | Yojson.Json_error msg -> Error ("JSON parse error: " ^ msg)
  | _ -> Error "Invalid message format"

let server_message_to_string msg =
  Yojson.Safe.to_string (server_message_to_yojson msg)
