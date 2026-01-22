(** A generic unbounded queue for Eio-based concurrency *)

type 'a t = 'a Eio.Stream.t

let create ?(capacity = 0) () =
  Eio.Stream.create capacity

let push queue value =
  Eio.Stream.add queue value

let pop_opt queue =
  Eio.Stream.take_nonblocking queue

let pop queue =
  Eio.Stream.take queue

let is_empty queue =
  Eio.Stream.is_empty queue
