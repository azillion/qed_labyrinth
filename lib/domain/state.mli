type t = { mutable last_tick : float; message_queue: Queue.t; }

val create : unit -> t

val update_tick : t -> unit
