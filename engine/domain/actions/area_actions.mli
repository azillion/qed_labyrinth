open Base

type t

(** Finds an area by its entity ID string and returns a rich handle. *)
val find_by_id : area_id_str:string -> (t, string) Result.t Lwt.t

(** Gets the area's entity ID as a string. *)
val get_id : t -> string

(** Finds an exit from a given area in a specific direction. *)
val find_exit : area:t -> direction:Components.ExitComponent.direction -> (Exit.t, string) Result.t Lwt.t

(** Finds an item present in a given area. *)
val find_item : area:t -> item_id_str:string -> (Item_actions.t, string) Result.t Lwt.t

(** Removes an item from the area (e.g., when it's picked up). *)
val remove_item : area:t -> item:Item_actions.t -> (unit, string) Result.t Lwt.t

(** Adds an item to the area (e.g., when it's dropped). *)
val add_item : area:t -> item:Item_actions.t -> (unit, string) Result.t Lwt.t

