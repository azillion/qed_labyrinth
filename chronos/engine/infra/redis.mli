(** Eio-based Redis client *)

(** Redis connection configuration *)
type config = {
  host : string;
  port : int;
}

(** Internal flow module signature *)
module type FLOW = sig
  val read : Eio.Buf_read.t
  val write : string -> unit
  val close : unit -> unit
end

(** A Redis connection handle *)
type connection

(** Exception raised on Redis errors *)
exception Redis_error of string

(** Connect to a Redis server.
    The connection is tied to the provided switch and will be closed when the switch completes. *)
val connect : sw:Eio.Switch.t -> net:_ Eio.Net.t -> config -> connection

(** Close the connection explicitly *)
val close : connection -> unit

(** {2 String Commands} *)

(** GET key - Get the value of a key *)
val get : connection -> string -> string option

(** SET key value - Set the string value of a key *)
val set : connection -> string -> string -> unit

(** {2 Hash Commands} *)

(** HSET key field value - Set the string value of a hash field.
    Returns 1 if field is new, 0 if field existed and was updated. *)
val hset : connection -> string -> string -> string -> int

(** HGET key field - Get the value of a hash field *)
val hget : connection -> string -> string -> string option

(** HDEL key field - Delete a hash field.
    Returns the number of fields removed. *)
val hdel : connection -> string -> string -> int

(** HMSET key (field, value) list - Set multiple hash fields *)
val hmset : connection -> string -> (string * string) list -> unit

(** HGETALL key - Get all fields and values in a hash *)
val hgetall : connection -> string -> (string * string) list

(** {2 Key Commands} *)

(** DEL keys - Delete one or more keys.
    Returns the number of keys removed. *)
val del : connection -> string list -> int

(** {2 Pub/Sub Commands} *)

(** PUBLISH channel message - Publish a message to a channel.
    Returns the number of clients that received the message. *)
val publish : connection -> string -> string -> int

(** SUBSCRIBE channels - Subscribe to one or more channels.
    After subscribing, use [read_message] to receive messages. *)
val subscribe : connection -> string list -> unit

(** Message received from a subscribed channel *)
type pubsub_message =
  | Message of { channel : string; payload : string }
  | Subscribe of { channel : string; count : int }
  | Unsubscribe of { channel : string; count : int }
  | Other of Resp.value

(** Read the next pub/sub message from a subscribed connection.
    This blocks until a message is available. *)
val read_message : connection -> pubsub_message
