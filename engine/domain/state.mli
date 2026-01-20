open Base

type t = {
  mutable last_tick : float;
  event_queue : (string option * Event.t) Infra.Queue.t;
  redis_conn : Redis_lwt.Client.connection;
  active_characters : (string, Uuidm.t) Hashtbl.t;
}

val create : Redis_lwt.Client.connection -> t
val update_tick : t -> unit

val enqueue : ?trace_id:string -> t -> Event.t -> unit Lwt.t

val set_active_character : t -> user_id:string -> entity_id:Uuidm.t -> unit
val unset_active_character : t -> user_id:string -> unit
val get_active_character : t -> string -> Uuidm.t option 