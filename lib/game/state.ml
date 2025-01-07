open Base

type t = {
  clients : (string, Client.t) Hashtbl.t;
  db : (module Caqti_lwt.CONNECTION);
  mutable last_tick : float;
}

let create db =
  {
    clients = Hashtbl.create (module String);
    db;
    last_tick = Unix.gettimeofday ();
  }

let add_client t client =
  Hashtbl.set t.clients ~key:client.Client.id ~data:client

let remove_client t client_id = Hashtbl.remove t.clients client_id

let broadcast t message =
  Hashtbl.iter t.clients ~f:(fun client ->
      Lwt.async (fun () -> client.Client.send message))

let update_tick t = t.last_tick <- Unix.gettimeofday ()
