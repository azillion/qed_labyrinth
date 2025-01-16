type t = {
  connection_manager : Connection_manager.t;
}

let create ~connection_manager =
  { connection_manager }
