type t = {
  id : string;
  name : string;
  description : string;
  x : int;
  y : int;
  z : int;
}

type error =
  | AreaNotFound
  | DatabaseError of string
[@@deriving yojson]

type direction = North | South | East | West | Up | Down
[@@deriving yojson]

val direction_to_string : direction -> string

type exit = {
  from_area_id : string;
  to_area_id : string;
  direction : direction;
  description : string option;
  hidden : bool;
  locked : bool;
}

val create :
  name:string ->
  description:string ->
  x:int ->
  y:int ->
  z:int ->
  (t, error) result Lwt.t

val find_by_id :
  string ->
  (t, error) result Lwt.t

val get_exits :
  t ->
  (exit list, error) result Lwt.t

val create_exit :
  from_area_id:string ->
  to_area_id:string ->
  direction:direction ->
  description:string option ->
  hidden:bool ->
  locked:bool ->
  (exit, error) result Lwt.t

val find_exits :
  area_id:string ->
  (exit list, error) result Lwt.t

val direction_equal : direction -> direction -> bool

module Q : sig
  val find_exit_by_direction : (string * direction, exit option, [ `Zero | `One ]) Caqti_request.t
end
