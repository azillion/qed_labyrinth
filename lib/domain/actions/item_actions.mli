open Base

type t

(** The possible effects a usable item can have. *)
type effect = [ `Heal of int ]

(** Finds an item instance by its entity ID string and returns a rich handle. *)
val find : item_entity_id_str:string -> (t, string) Result.t Lwt.t

(** Gets the item's name. *)
val get_name : item:t -> string

(** Checks if the item is of a type that can be "used". *)
val is_usable : item:t -> bool

(** Gets the usable effect of the item, if any. *)
val get_effect : item:t -> effect option

(** Gets the item's entity ID as a string. *)
val get_id : item:t -> string

(** Gets the item's intended equipment slot. *)
val get_slot : item:t -> Item_definition.slot Lwt.t

