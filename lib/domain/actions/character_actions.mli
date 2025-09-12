open Base

type t

(** Finds the character a user is currently controlling, handling all auth checks. *)
val find_active : state:State.t -> user_id:string -> (t, string) Result.t Lwt.t

(** Gets the character's name. *)
val get_name : character:t -> (string, Qed_error.t) Result.t Lwt.t

(** Gets the character's id as a string. *)
val get_id : character:t -> string

(** Constructs a character handle from ids for internal use. *)
val of_ids : entity_id:Uuidm.t -> user_id:string -> t

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

(** High-level action to use an item. Orchestrates all sub-steps. *)
val use : state:State.t -> character:t -> item:Item_actions.t -> (string, string) Result.t Lwt.t

(** Sends a system message to the character's player. *)
val send_message : state:State.t -> character:t -> message:string -> (unit, Qed_error.t) Result.t Lwt.t

(** Triggers all necessary client UI updates after an action. *)
val refresh_client_ui : state:State.t -> character:t -> (unit, Qed_error.t) Result.t Lwt.t

(** Gets the rich area handle for the character's current location. *)
val get_area : character:t -> (Area_actions.t, string) Result.t Lwt.t

(** Gets or initializes the character's inventory component. *)
val get_inventory : character:t -> (Components.InventoryComponent.t, Qed_error.t) Result.t Lwt.t

(** High-level action for moving a character. Handles all logic and side-effects. *)
val move : state:State.t -> character:t -> direction:Components.ExitComponent.direction -> (unit, string) Result.t Lwt.t

(** High-level action for taking an item from the current area. *)
val take : state:State.t -> character:t -> item:Item_actions.t -> (unit, string) Result.t Lwt.t

(** High-level action for dropping an item into the current area. *)
val drop : state:State.t -> character:t -> item:Item_actions.t -> (unit, string) Result.t Lwt.t

(** High-level action for a character to say something in their current area. *)
val say : state:State.t -> character:t -> content:string -> (unit, string) Result.t Lwt.t
