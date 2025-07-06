open Base

(* Publishing helper functions extracted from Loop *)

let publish_event (state : State.t) (event : Schemas_generated.Output.output_event) =
  let open Lwt.Syntax in
  let encoder = Pbrt.Encoder.create () in
  Schemas_generated.Output.encode_pb_output_event event encoder;
  let serialized = Pbrt.Encoder.to_string encoder in
  let* _ = Redis_lwt.Client.publish state.State.redis_conn "engine_events" serialized in
  Lwt.return_unit

let publish_system_message_to_user (state : State.t) (user_id : string) (content : string) =
  let chat_message = Schemas_generated.Output.{
    sender_name = "System";
    content;
    message_type = "System";
  } in
  let output_event = Schemas_generated.Output.{
    target_user_ids = [user_id];
    payload = Chat_message chat_message;
  } in
  publish_event state output_event 