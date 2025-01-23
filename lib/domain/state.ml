type t = {
  mutable last_tick : float;
  message_queue: Queue.t;
}

let create () =
  {
    last_tick = Unix.gettimeofday ();
    message_queue = Queue.create ();
  }

let update_tick t = t.last_tick <- Unix.gettimeofday ()
