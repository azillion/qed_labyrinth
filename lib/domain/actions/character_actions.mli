open Base

type t

(** Finds the character a user is currently controlling, handling all auth checks. *)
val find_active : state:State.t -> user_id:string -> (t, string) Result.t Lwt.t

(** Gets the character's name. *)
val get_name : character:t -> (string, Qed_error.t) Result.t Lwt.t

(** Gets the character's id as a string. *)
val get_id : character:t -> string

(** Gets the character's health as a (current, max) tuple. *)
val get_health : character:t -> (int * int) option Lwt.t

(** Gets the character's action points as a (current, max) tuple. *)
val get_action_points : character:t -> (int * int) option Lwt.t

(** Gets the character's core attributes. *)
val get_core_stats : character:t -> Types.core_attributes option Lwt.t

(** Gets the character's derived stats. *)
val get_derived_stats : character:t -> Types.derived_stats option Lwt.t

(** Gets the character's progression info as (level, power_budget). *)
val get_progression : character:t -> (int * int) option Lwt.t

