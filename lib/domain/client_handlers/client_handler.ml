module type S = sig
  val handle : State.t -> Client.t -> Protocol.client_message -> unit Lwt.t
end
