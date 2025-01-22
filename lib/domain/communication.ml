open Infra

type message_type = Chat | Emote | System [@@deriving yojson]

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

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let message_type_t =
    let encode = function
      | Chat -> Ok "chat"
      | Emote -> Ok "emote"
      | System -> Ok "system"
    in
    let decode = function
      | "chat" -> Ok Chat
      | "emote" -> Ok Emote
      | "system" -> Ok System
      | _ -> Error "Invalid message type"
    in
    custom ~encode ~decode string

  let message_t =
    let encode { id; message_type; sender_id; content; area_id; timestamp } =
      Ok (id, message_type, sender_id, content, area_id, timestamp)
    in
    let decode (id, message_type, sender_id, content, area_id, timestamp) =
      Ok { id; message_type; sender_id; content; area_id; timestamp }
    in
    custom ~encode ~decode
      (t6 string message_type_t (option string) string (option string) ptime)

  let insert =
    (message_t ->. unit)
      {| INSERT INTO communications (id, message_type, sender_id, content, area_id, timestamp)
         VALUES (?, ?, ?, ?, ?, ?) |}

  let find_by_area_id =
    (string ->* message_t)
      {| SELECT id, message_type, sender_id, content, area_id, timestamp
         FROM communications 
         WHERE area_id = ?
         ORDER BY timestamp DESC
         LIMIT 50 |}
end

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

let validate_content content =
  if String.length content > 0 && String.length content <= 1000 then
    Ok ()
  else
    Error InvalidContent

let create ~message_type ~sender_id ~content ~area_id =
  let open Base in
  let open Lwt.Syntax in
  match validate_content content with
  | Error e -> Lwt.return_error e
  | Ok () -> (
      let message =
        {
          id = Uuidm.to_string (uuid ());
          message_type;
          sender_id;
          content;
          area_id;
          timestamp = Ptime_clock.now ();
        }
      in
      let db_operation (module Db : Caqti_lwt.CONNECTION) =
        match%lwt Db.exec Q.insert message with
        | Ok () -> Lwt_result.return message
        | Error e -> Lwt_result.fail e
      in
      let* result = Database.Pool.use db_operation in
      match result with
      | Ok message -> Lwt.return_ok message
      | Error e -> 
          let error_string = Printf.sprintf "Error: %s" (Error.to_string_hum e) in
          ignore(Stdio.printf "%s\n" error_string);
          Lwt.return_error (DatabaseError error_string))

let find_by_area_id area_id =
  let open Base in
  let open Lwt.Syntax in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* result = Db.collect_list Q.find_by_area_id area_id in
    match result with
    | Ok messages -> Lwt_result.return messages
    | Error e -> Lwt_result.fail e
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok messages -> Lwt.return_ok messages
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
