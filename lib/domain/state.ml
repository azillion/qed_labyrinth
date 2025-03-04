type client_message_with_client = {
  message: Protocol.client_message;
  client: Client.t;
}

type t = {
  mutable last_tick : float;
  client_message_queue: client_message_with_client Infra.Queue.t;
  connection_manager: Connection_manager.t;
}

let create () =
  {
    last_tick = Unix.gettimeofday ();
    client_message_queue = Infra.Queue.create ();
    connection_manager = Connection_manager.create ();
  }

let update_tick t = t.last_tick <- Unix.gettimeofday ()
