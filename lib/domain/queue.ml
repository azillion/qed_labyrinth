type t = {
  queue: Protocol.client_message Lwt_mvar.t;
}

let create () = {
  queue = Lwt_mvar.create_empty ();
}

let push queue msg = Lwt_mvar.put queue.queue msg
let pop queue = Lwt_mvar.take queue.queue
