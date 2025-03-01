type client_message_with_client = {
  message: Protocol.client_message;
  client: Client.t;
}

type t

val create : unit -> t

val push : t -> Protocol.client_message -> Client.t -> unit Lwt.t

val pop_opt : t -> client_message_with_client option Lwt.t