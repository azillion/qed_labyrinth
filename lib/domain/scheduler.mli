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

(** The signature every system handler must implement. *)
type handler = State.t -> string option -> Event.t option -> (unit, Qed_error.t) Result.t Lwt.t

(**
  Register a system handler to run in a specific schedule when its criteria are met.
  @param schedule The schedule to run in (e.g., Update).
  @param criteria The condition that triggers the system (e.g., OnEvent "TakeItem").
  @param handler The function to execute.
*)
val register : schedule:schedule -> criteria:run_criteria -> handler -> unit

(**
  Run all systems registered for a given schedule whose run criteria are met.
  This function is the new heart of the game loop's event processing.
  It is responsible for dequeuing events and dispatching them to the correct systems.
  @param schedule The schedule to run.
  @param state The current world state.
*)
val run : schedule -> State.t -> unit Lwt.t 