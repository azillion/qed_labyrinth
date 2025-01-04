type content_type = AreaDescription | Characters | CommandList
[@@deriving yojson]

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

type client_message =
  | Command of { content : command_content }
  | Subscribe of { content_types : content_type list }
  | Unsubscribe of { content_types : content_type list }
[@@deriving yojson]

type server_message = StateUpdate of content_update list | Error of string
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
