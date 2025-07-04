open Base

type client_message_with_client = {
  message: Protocol.client_message;
  client: Client.t;
}

type t = {
  mutable last_tick : float;
  client_message_queue: client_message_with_client Infra.Queue.t;
  event_queue: Event.t Infra.Queue.t;
  connection_manager: Connection_manager.t;
  (** Map of user_id -> currently active character entity *)
  active_characters: (string, Uuidm.t) Base.Hashtbl.t;
}

let create () =
  {
    last_tick = Unix.gettimeofday ();
    client_message_queue = Infra.Queue.create ();
    event_queue = Infra.Queue.create ();
    connection_manager = Connection_manager.create ();
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
