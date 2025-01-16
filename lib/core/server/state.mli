type t = {
  connection_manager : Connection_manager.t;
}

val create : connection_manager:Connection_manager.t -> t
