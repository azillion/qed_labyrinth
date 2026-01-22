(** Application state for the game engine *)

open Infra

(** The application state type.
    Parameterized by the event type to allow flexibility. *)
type 'event t = {
  mutable last_tick : float;
  event_queue : (string option * 'event) Queue.t;
  redis_conn : Redis.connection;
  active_characters : (string, Uuidm.t) Hashtbl.t;
}

(** Create a new application state with a Redis connection *)
val create : Redis.connection -> 'event t

(** Update the last tick timestamp to current time *)
val update_tick : 'event t -> unit

(** Enqueue an event with optional trace ID *)
val enqueue : ?trace_id:string -> 'event t -> 'event -> unit

(** Set the active character for a user *)
val set_active_character : 'event t -> user_id:string -> entity_id:Uuidm.t -> unit

(** Remove the active character for a user *)
val unset_active_character : 'event t -> user_id:string -> unit

(** Get the active character entity ID for a user *)
val get_active_character : 'event t -> string -> Uuidm.t option
