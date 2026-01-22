(** Event publishing to Redis *)

let engine_events_channel = "engine_events"
let player_commands_channel = "player_commands"

let publish_raw state message =
  Infra.Redis.publish state.State.redis_conn engine_events_channel message

let publish ~serialize state ?trace_id event =
  let _ = trace_id in (* trace_id can be embedded by the serialize function if needed *)
  let message = serialize event in
  publish_raw state message
