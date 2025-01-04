(* lib/server/websocket.ml *)
open Protocol.Message

type client = {
  id : string;
  ws : Dream.websocket;
  mutable subscriptions : content_type list;
}

let clients = ref []
let clients_mutex = Lwt_mutex.create ()

let add_client client =
  Lwt_mutex.with_lock clients_mutex (fun () ->
      clients := client :: !clients;
      Lwt.return_unit)

let remove_client client_id =
  Lwt_mutex.with_lock clients_mutex (fun () ->
      clients := List.filter (fun c -> c.id <> client_id) !clients;
      Lwt.return_unit)

let broadcast updates =
  Lwt_mutex.with_lock clients_mutex (fun () ->
      Lwt_list.iter_p
        (fun client ->
          let relevant_updates =
            List.filter
              (fun update -> List.mem update.content_type client.subscriptions)
              updates
          in
          if relevant_updates <> [] then
            Lwt.catch
              (fun () ->
                let%lwt () =
                  Dream.send client.ws
                    (server_message_to_string (StateUpdate relevant_updates))
                in
                Lwt.return_unit)
              (fun _ ->
                let%lwt () = remove_client client.id in
                Lwt.return_unit)
          else
            Lwt.return_unit)
        !clients)

let random_id () =
  let timestamp = Unix.gettimeofday () in
  let ctx = Digestif.SHA1.init () in
  let ctx = Digestif.SHA1.feed_string ctx "client" in
  let ctx = Digestif.SHA1.feed_string ctx (string_of_float timestamp) in
  let hash = Digestif.SHA1.get ctx in
  String.sub (Digestif.SHA1.to_hex hash) 0 32

let handle_client ws =
  let client_id = random_id () in
  let client = { id = client_id; ws; subscriptions = [] } in
  let%lwt () = add_client client in

  let handle_message msg =
    match client_message_of_string msg with
    | Ok (Subscribe { content_types }) ->
        client.subscriptions <- content_types;
        Lwt.return_unit
    | Ok (Unsubscribe { content_types }) ->
        client.subscriptions <- List.filter (fun ct -> not (List.mem ct content_types)) client.subscriptions;
        Lwt.return_unit
    | Ok (Command { content = _ }) ->
        (* implement command handling here *)
        Lwt.return_unit
    | Error err ->
        let%lwt () =
          Dream.send ws (server_message_to_string (Error err))
        in
        Lwt.return_unit
  in

  let rec loop () =
    Lwt.catch
      (fun () ->
        let%lwt msg_opt = Dream.receive ws in
        match msg_opt with
        | Some msg ->
            let%lwt () = handle_message msg in
            loop ()
        | None ->
            let%lwt () = remove_client client_id in
            Lwt.return_unit)
      (fun _ ->
        let%lwt () = remove_client client_id in
        Lwt.return_unit)
  in
  loop ()

let start port =
  Dream.run ~port @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/ws" (fun _ ->
           Dream.websocket (fun ws -> handle_client ws));
       ]
  |> Lwt.return

let stop () =
  Lwt_mutex.with_lock clients_mutex (fun () ->
      let%lwt () =
        Lwt_list.iter_p
          (fun client ->
            Lwt.catch
              (fun () -> Dream.close_websocket client.ws)
              (fun _ -> Lwt.return_unit))
          !clients
      in
      clients := [];
      Lwt.return_unit)
