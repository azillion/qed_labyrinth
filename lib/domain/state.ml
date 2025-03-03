type t = {
  mutable last_tick : float;
  client_message_queue: Queue.t;
  connection_manager: Connection_manager.t;
}

let create () =
  {
    last_tick = Unix.gettimeofday ();
    client_message_queue = Queue.create ();
    connection_manager = Connection_manager.create ();
  }

let update_tick t = t.last_tick <- Unix.gettimeofday ()
