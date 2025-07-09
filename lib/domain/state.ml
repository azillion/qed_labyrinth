open Base

type t = {
  mutable last_tick : float;
  event_queue: Event.t Infra.Queue.t;
  redis_conn: Redis_lwt.Client.connection;
  (** Map of user_id -> currently active character entity *)
  active_characters: (string, Uuidm.t) Base.Hashtbl.t;
}

let create redis_conn =
  {
    last_tick = Unix.gettimeofday ();
    event_queue = Infra.Queue.create ();
    redis_conn;
    active_characters = Base.Hashtbl.create (module String);
  }

let update_tick t = t.last_tick <- Unix.gettimeofday ()

(* Active character helpers *)

let set_active_character t ~user_id ~entity_id =
  Base.Hashtbl.set t.active_characters ~key:user_id ~data:entity_id

let unset_active_character t ~user_id =
  Base.Hashtbl.remove t.active_characters user_id

let get_active_character t user_id =
  Base.Hashtbl.find t.active_characters user_id
