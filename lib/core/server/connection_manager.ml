open Base

type t = {
  clients : (string, Client.t) Hashtbl.t;
}

let create () = {
  clients = Hashtbl.create (module String);
}

let add_client t client =
  Hashtbl.set t.clients ~key:client.Client.id ~data:client

let remove_client t client_id = Hashtbl.remove t.clients client_id

let broadcast t message =
  Hashtbl.iter t.clients ~f:(fun client ->
      Lwt.async (fun () -> client.send message))
