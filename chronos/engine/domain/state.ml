(** Application state for the game engine *)

open Infra

type 'event t = {
  mutable last_tick : float;
  event_queue : (string option * 'event) Queue.t;
  redis_conn : Redis.connection;
  active_characters : (string, Uuidm.t) Hashtbl.t;
}

let create redis_conn =
  {
    last_tick = Unix.gettimeofday ();
    event_queue = Queue.create ();
    redis_conn;
    active_characters = Hashtbl.create 64;
  }

let update_tick t =
  t.last_tick <- Unix.gettimeofday ()

let enqueue ?trace_id t event =
  Queue.push t.event_queue (trace_id, event)

let set_active_character t ~user_id ~entity_id =
  Hashtbl.replace t.active_characters user_id entity_id

let unset_active_character t ~user_id =
  Hashtbl.remove t.active_characters user_id

let get_active_character t user_id =
  Hashtbl.find_opt t.active_characters user_id
