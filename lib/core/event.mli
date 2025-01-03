type base = { id : string; timestamp : float } [@@deriving yojson]

module Movement : sig
  type t = {
    base : base;
    from_space_id : Space.id;
    to_space_id : Space.id;
    direction : string;
  }
  [@@deriving yojson]
end

module Observation : sig
  type t = { base : base; space_id : Space.id } [@@deriving yojson]
end

type t = PlayerMoved of Movement.t | PlayerLooked of Observation.t
[@@deriving yojson]

val get_id : t -> string
val get_timestamp : t -> float

val player_moved :
  from_space_id:Space.id -> to_space_id:Space.id -> direction:string -> t

val player_looked : space_id:Space.id -> t
