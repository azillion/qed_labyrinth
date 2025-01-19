type t = {
  mutable last_tick : float;
}

let create () =
  {
    last_tick = Unix.gettimeofday ();
  }

let update_tick t = t.last_tick <- Unix.gettimeofday ()
