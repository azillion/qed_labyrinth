open Base

type t = {
  clients: (string, Client.t) Hashtbl.t;
  rooms: (string, string list) Hashtbl.t;  (* room_id -> client_ids *)
  client_rooms: (string, string) Hashtbl.t; (* client_id -> room_id *)
}

let create () = {
  clients = Hashtbl.create (module String);
  rooms = Hashtbl.create (module String);
  client_rooms = Hashtbl.create (module String);
}

(* Core client management *)
let add_client t client =
  Hashtbl.set t.clients ~key:client.Client.id ~data:client

let remove_client t client_id =
  (* First remove from any room they're in *)
  match Hashtbl.find t.client_rooms client_id with
  | Some room_id ->
      let room_clients = Hashtbl.find_exn t.rooms room_id in
      Hashtbl.set t.rooms ~key:room_id 
        ~data:(List.filter room_clients ~f:(fun id -> not (String.equal id client_id)));
      Hashtbl.remove t.client_rooms client_id
  | None -> ();
  Hashtbl.remove t.clients client_id

(* Find a client by the user_id in their authentication state *)
let find_client_by_user_id t user_id =
  Hashtbl.fold t.clients ~init:None ~f:(fun ~key:_ ~data:client acc ->
    match acc with
    | Some _ -> acc
    | None ->
        match client.Client.auth_state with
        | Client.Authenticated { user_id = client_user_id; _ } when String.equal client_user_id user_id ->
            Some client
        | _ -> None
  )

(* Room management *)
let add_to_room t ~client_id ~room_id =
  (* First remove from any existing room *)
  begin match Hashtbl.find t.client_rooms client_id with
  | Some old_room_id when not (String.equal old_room_id room_id) ->
      let old_room_clients = Hashtbl.find_exn t.rooms old_room_id in
      Hashtbl.set t.rooms ~key:old_room_id
        ~data:(List.filter old_room_clients ~f:(fun id -> 
          not (String.equal id client_id)))
  | _ -> ()
  end;
  
  (* Add to new room *)
  let room_clients = Option.value (Hashtbl.find t.rooms room_id) ~default:[] in
  Hashtbl.set t.rooms ~key:room_id ~data:(client_id :: room_clients);
  Hashtbl.set t.client_rooms ~key:client_id ~data:room_id

let remove_from_room t client_id =
  match Hashtbl.find t.client_rooms client_id with
  | Some room_id ->
      let room_clients = Hashtbl.find_exn t.rooms room_id in
      Hashtbl.set t.rooms ~key:room_id
        ~data:(List.filter room_clients ~f:(fun id -> 
          not (String.equal id client_id)));
      Hashtbl.remove t.client_rooms client_id
  | None -> ()

(* Broadcasting *)
let broadcast_to_room t room_id message =
  match Hashtbl.find t.rooms room_id with
  | Some client_ids ->
      List.iter client_ids ~f:(fun client_id ->
        match Hashtbl.find t.clients client_id with
        | Some client -> 
            Lwt.async (fun () -> client.send message)
        | None -> ())
  | None -> ()

let broadcast t message =
  Hashtbl.iteri t.clients ~f:(fun ~key:_ ~data:client ->
    Lwt.async (fun () -> client.send message))

(* Room transitions *)
let move_client t ~client_id ~new_room_id =
  add_to_room t ~client_id ~room_id:new_room_id