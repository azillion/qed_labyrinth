type t = { mutable last_tick : float; message_queue: Queue.t; connection_manager: Connection_manager.t; }

val create : unit -> t

val update_tick : t -> unit
