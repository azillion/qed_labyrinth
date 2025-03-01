type client_message_with_client = {
  message: Protocol.client_message;
  client: Client.t;
}

type t = {
  stream: client_message_with_client Lwt_stream.t;
  push: client_message_with_client option -> unit;
}

let create () =
  let (stream, push) = Lwt_stream.create () in
  { stream; push }

let push queue msg client =
  queue.push (Some { message = msg; client });
  Lwt.return_unit

let pop_opt queue =
  Lwt_stream.get queue.stream
