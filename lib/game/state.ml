open Base

type t = {
  clients : (string, Client.t) Hashtbl.t;
  db_pool : (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt_unix.Pool.t;
  mutable last_tick : float;
}

let create pool =
  {
    clients = Hashtbl.create (module String);
    db_pool = pool;
    last_tick = Unix.gettimeofday ();
  }

let add_client t client =
  Hashtbl.set t.clients ~key:client.Client.id ~data:client

let remove_client t client_id = Hashtbl.remove t.clients client_id

let broadcast t message =
  Hashtbl.iter t.clients ~f:(fun client ->
      Lwt.async (fun () -> client.Client.send message))

let update_tick t = t.last_tick <- Unix.gettimeofday ()

(* Helper to safely use database connection *)
let with_db t (f : (module Caqti_lwt.CONNECTION) -> ('a, 'e) Result.t Lwt.t) =
  let open Lwt.Syntax in
  let* db_result =
    Caqti_lwt_unix.Pool.use
      (fun db ->
        let* result = f db in
        Lwt.return (Ok result))
      t.db_pool
  in
  match db_result with
  | Error e ->
      (* Convert pool errors to domain DatabaseError *)
      Lwt.return (Error (Model.User.DatabaseError (Caqti_error.show e)))
  | Ok (Error _e as err) -> Lwt.return err (* Preserve domain error *)
  | Ok (Ok v) -> Lwt.return (Ok v)
