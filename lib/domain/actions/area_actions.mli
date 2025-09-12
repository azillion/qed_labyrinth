open Base

type t

(** Finds an area by its entity ID string and returns a rich handle. *)
val find_by_id : area_id_str:string -> (t, string) Result.t Lwt.t

(** Gets the area's entity ID as a string. *)
val get_id : t -> string

(** Finds an exit from a given area in a specific direction. *)
val find_exit : area:t -> direction:Components.ExitComponent.direction -> (Exit.t, string) Result.t Lwt.t

