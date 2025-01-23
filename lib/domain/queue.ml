type client_message_with_client = {
  message: Protocol.client_message;
  client: Client.t;
}

type t = {
  queue: client_message_with_client Lwt_mvar.t;
}

let create () = {
  queue = Lwt_mvar.create_empty ();
}

let push queue msg client = Lwt_mvar.put queue.queue { message = msg; client }

let pop_opt queue = 
  Lwt.return (Lwt_mvar.take_available queue.queue)
