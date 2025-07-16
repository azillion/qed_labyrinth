open Base

(**
  The interface for a self-contained, observable, and dispatchable game system.
*)
module type S = sig
  (** A unique, kebab-case name for the system (e.g., "take-item").
      Used for logging and metrics. *)
  val name : string

  (** The specific event payload this system handles. *)
  type event

  (** A safe casting function from the generic event type to this system's
      specific event type. Returns None if the event is not for this system. *)
  val event_type : Event.t -> event option

  (** The core logic of the system.
      @param state The current world state.
      @param trace_id The optional trace_id for distributed tracing.
      @param event The specific event payload to process.
      @return A result indicating success or a QED error.
  *)
  val execute : State.t -> string option -> event -> (unit, Qed_error.t) Result.t Lwt.t
end

(**
  A functor that takes a system logic module and wraps it with observability
  (logging, metrics, timing) and a standardized handler interface.
*)
module Make (Sys : S) : sig
  (** The standardized `handle` function that is registered with the scheduler.
      It performs the event type check and calls the wrapped `execute` function. *)
  val handle : State.t -> string option -> Event.t option -> (unit, Qed_error.t) Result.t Lwt.t
end 