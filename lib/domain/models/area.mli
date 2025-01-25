type climate = {
  elevation: float;
  temperature: float;
  moisture: float;
} [@@deriving yojson]

type room_type = 
  | Cave 
  | Forest 
  | Mountain 
  | Swamp 
  | Desert 
  | Tundra 
  | Lake 
  | Canyon [@@deriving yojson]

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
type direction = North | South | East | West | Up | Down [@@deriving yojson]

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

val get_climate : t -> climate option
val get_room_type : t -> room_type option
val get_climate_description : t -> string
val get_room_type_description : room_type -> string
val get_full_description : t -> string

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

module Q : sig
  val find_exit_by_direction :
    (string * direction, exit option, [ `Zero | `One ]) Caqti_request.t
end
