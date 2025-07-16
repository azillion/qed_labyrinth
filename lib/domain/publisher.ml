open Base
open Infra

(* Publishing helper functions extracted from Loop *)

let publish_event (state : State.t) ?trace_id (event : Schemas_generated.Output.output_event) : (unit, Qed_error.t) Lwt_result.t =
  let trace_id = Option.value trace_id ~default:"" in
  let event_with_trace = { event with trace_id } in
  let encoder = Pbrt.Encoder.create () in
  Schemas_generated.Output.encode_pb_output_event event_with_trace encoder;
  let serialized = Pbrt.Encoder.to_string encoder in
  (* Redis publish returns int Lwt.t; wrap any exception *)
  let redis_op = Redis_lwt.Client.publish state.State.redis_conn "engine_events" serialized |> Lwt.map (fun _ -> ()) in
  let%lwt () = Monitoring.Log.info "Publishing event to Redis" ~data:[("channel", "engine_events"); ("trace_id", trace_id)] () in
  Error_utils.wrap_ok redis_op

let publish_system_message_to_user (state : State.t) ?trace_id (user_id : string) (content : string) : (unit, Qed_error.t) Lwt_result.t =
  let chat_message = Schemas_generated.Output.{
    sender_name = "System";
    content;
    message_type = "System";
  } in
  let output_event = Schemas_generated.Output.{
    target_user_ids = [user_id];
    payload = Chat_message chat_message;
    trace_id = ""; (* This will be set by publish_event *)
  } in
  publish_event state ?trace_id output_event 