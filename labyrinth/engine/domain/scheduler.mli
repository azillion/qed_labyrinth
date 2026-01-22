open Base

(** The different phases of the game loop in which systems can run. *)
type schedule =
  | PreUpdate
  | Update
  | PostUpdate

(** Conditions that determine when a system should execute. *)
type run_criteria =
  | OnEvent of string  (* The event key, from Loop.string_of_event_type *)
  | OnTick             (* Runs every game loop tick for the given schedule *)
  | OnComponentChange of string  (* Runs when a component storage has modified entities *)

(** The signature every system handler must implement. *)
type handler = State.t -> string option -> Event.t option -> (unit, Qed_error.t) Result.t Lwt.t

(**
  Register a system handler.
  @param name A unique name for this system (e.g., "ap-regen").
  @param schedule The schedule to run in.
  @param criteria The condition that triggers the system.
  @param before An optional list of system names this system must run before.
  @param after An optional list of system names this system must run after.
  @param handler The function to execute.
*)
val register :
  name:string ->
  schedule:schedule ->
  criteria:run_criteria ->
  ?before:string list ->
  ?after:string list ->
  handler ->
  unit

(**
  Run all systems registered for a given schedule whose run criteria are met,
  respecting their ordering dependencies.
  @param events Optional pre-drained list of events to use instead of draining
                the state's event queue.
*)
val run : ?events:(string option * Event.t) list -> schedule -> State.t -> unit Lwt.t 