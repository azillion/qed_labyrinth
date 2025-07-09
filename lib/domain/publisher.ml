open Base

(* Publishing helper functions extracted from Loop *)

let publish_event (state : State.t) (event : Schemas_generated.Output.output_event) : (unit, Qed_error.t) Lwt_result.t =
  let encoder = Pbrt.Encoder.create () in
  Schemas_generated.Output.encode_pb_output_event event encoder;
  let serialized = Pbrt.Encoder.to_string encoder in
  (* Redis publish returns int Lwt.t; wrap any exception *)
  let redis_op = Redis_lwt.Client.publish state.State.redis_conn "engine_events" serialized |> Lwt.map (fun _ -> ()) in
  Error_utils.wrap_ok redis_op

let publish_system_message_to_user (state : State.t) (user_id : string) (content : string) : (unit, Qed_error.t) Lwt_result.t =
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