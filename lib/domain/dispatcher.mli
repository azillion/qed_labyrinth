open Base

(** A type for a handler function that can process a generic event. *)
type handler = State.t -> string option -> Event.t -> (unit, Qed_error.t) Result.t Lwt.t

(** Register a handler for a given event type key. *)
val register : string -> handler -> unit

(**
  Dispatch an event to its registered handler.
  If no handler is found, it returns Ok () and logs a warning.
*)
val dispatch : State.t -> string option -> Event.t -> (unit, Qed_error.t) Result.t Lwt.t

(** Check if a handler is registered for a given event type key. *)
val has_handler : string -> bool

(** Convert an Event.t to its string key representation. *)
val string_of_event_type : Event.t -> string

(** Placeholder for registering legacy ECS systems (no-op for now). *)
val register_legacy_systems : unit -> unit Lwt.t 