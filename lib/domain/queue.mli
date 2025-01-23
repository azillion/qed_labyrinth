type t = {
  queue: Protocol.client_message Lwt_mvar.t;
}

val create : unit -> t

val push : t -> Protocol.client_message -> unit Lwt.t

val pop : t -> Protocol.client_message Lwt.t
