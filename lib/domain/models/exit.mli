open Base

type direction = Components.ExitComponent.direction

type t = {
  id: string;
  from_area_id: string;
  to_area_id: string;
  direction: direction;
  description: string option;
  hidden: bool;
  locked: bool;
}

val create :
  from_area_id:string ->
  to_area_id:string ->
  direction:direction ->
  description:string option ->
  hidden:bool ->
  locked:bool ->
  (t, Qed_error.t) Result.t Lwt.t

val find_by_area_and_direction :
  area_id:string ->
  direction:direction ->
  (t option, Qed_error.t) Result.t Lwt.t

val find_by_area :
  area_id:string ->
  (t list, Qed_error.t) Result.t Lwt.t