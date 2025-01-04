open Protocol.Message

type client = private {
  id : string;
  ws : Dream.websocket;
  mutable subscriptions : content_type list;
}

(* Client management *)
val add_client : client -> unit Lwt.t
val remove_client : string -> unit Lwt.t

(* Broadcast updates to all subscribed clients *)
val broadcast : content_update list -> unit Lwt.t

(* Start/stop server *)
val start : int -> unit Lwt.t
val stop : unit -> unit Lwt.t
