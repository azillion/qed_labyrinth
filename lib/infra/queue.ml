type 'a t = {
  stream: 'a Lwt_stream.t;
  push: 'a option -> unit;
}

let create () =
  let (stream, push) = Lwt_stream.create () in
  { stream; push }

let push queue value =
  queue.push (Some value);
  Lwt.return_unit

let pop_opt queue =
  Lwt_stream.get queue.stream