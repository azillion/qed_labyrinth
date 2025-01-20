open Base

type t = { clients : (string, Client.t) Hashtbl.t }

let termination_message = "Connection terminated"
let create () = { clients = Hashtbl.create (module String) }

let add_client t client =
  Hashtbl.set t.clients ~key:client.Client.id ~data:client

let remove_client t client_id = Hashtbl.remove t.clients client_id

let broadcast t message =
  Hashtbl.iter t.clients ~f:(fun client ->
      Lwt.async (fun () -> client.send message))

(* Drop a specific client's connection *)
let drop_connection t client_id =
  let open Lwt.Syntax in
  match Hashtbl.find t.clients client_id with
  | Some client ->
      (* Send close message and remove from clients *)
      Lwt.async (fun () ->
          let* _ = client.send (Api.Protocol.Error (Api.Protocol.error_response_of_string termination_message)) in
          match client.websocket with
          | Some websocket -> Dream.close_websocket websocket
          | None -> Lwt.return_unit);
      remove_client t client_id
  | None -> ()

(* Drop all connections for a user *)
let drop_user_connections t user_id =
  let open Lwt.Syntax in
  Hashtbl.filter_inplace t.clients ~f:(fun client ->
      match client.Client.auth_state with
      | Anonymous -> true (* Keep anonymous connections *)
      | Authenticated { user_id = uid; _ } ->
          if String.equal uid user_id then (
            Lwt.async (fun () ->
                let* _ = client.send (Api.Protocol.Error (Api.Protocol.error_response_of_string termination_message)) in
                match client.websocket with
                | Some websocket -> Dream.close_websocket websocket
                | None -> Lwt.return_unit);
            false (* Remove this connection *))
          else
            true
      (* Keep other users' connections *))
