type climate = {
  elevation: float;
  temperature: float;
  moisture: float;
} [@@deriving yojson]

type room_type = 
  | Cave 
  | Forest 
  | Grassland
  | Mountain 
  | Swamp 
  | Desert 
  | Tundra 
  | Lake 
  | Canyon 
  | Volcano 
  | Jungle [@@deriving yojson]

type t = {
  id : string;
  name : string;
  description : string;
  x : int;
  y : int;
  z : int;
  elevation : float option;
  temperature : float option;
  moisture : float option;
}

type error = AreaNotFound | DatabaseError of string [@@deriving yojson]

val error_to_string : error -> string

type direction = North | South | East | West | Up | Down [@@deriving yojson]

val opposite_direction : direction -> direction
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
  ?elevation:float ->
  ?temperature:float ->
  ?moisture:float ->
  unit ->
  (t, error) result Lwt.t

val create_with_climate :
  name:string ->
  description:string ->
  x:int ->
  y:int ->
  z:int ->
  climate:climate ->
  unit ->
  (t, error) result Lwt.t

val find_by_id : string -> (t, error) result Lwt.t
val find_by_coordinates : x:int -> y:int -> z:int -> (t, error) result Lwt.t
val exists : x:int -> y:int -> z:int -> (bool, error) result Lwt.t

val get_exits : t -> (exit list, error) result Lwt.t
val create_exit :
  from_area_id:string ->
  to_area_id:string ->
  direction:direction ->
  description:string option ->
  hidden:bool ->
  locked:bool ->
  (exit, error) result Lwt.t

val find_exits : area_id:string -> (exit list, error) result Lwt.t
val direction_equal : direction -> direction -> bool

val delete_all_except_starting_area : string -> (unit, error) result Lwt.t

val get_all_areas : unit -> (t list, error) result Lwt.t
val get_all_exits : unit -> (exit list, error) result Lwt.t
val get_all_nearby_areas : string -> max_distance:int -> (t list, error) result Lwt.t

val update_area_name_and_description : location_id:string -> name:string -> description:string -> (unit, error) result Lwt.t

module Q : sig
  val find_exit_by_direction :
    (string * direction, exit option, [ `Zero | `One ]) Caqti_request.t
  val insert_exit : (exit, unit, [ `Zero ]) Caqti_request.t
end
