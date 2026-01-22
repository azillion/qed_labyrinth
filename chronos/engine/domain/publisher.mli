(** Event publishing to Redis *)

(** Publish a raw string message to the engine_events channel.
    Returns the number of clients that received the message. *)
val publish_raw : 'event State.t -> string -> int

(** Publish a message with optional trace ID.
    The serialize function converts the event to a string for transmission. *)
val publish : 
  serialize:('a -> string) -> 
  'event State.t -> 
  ?trace_id:string -> 
  'a -> 
  int

(** The default channel name for engine events *)
val engine_events_channel : string

(** The default channel name for player commands *)
val player_commands_channel : string
