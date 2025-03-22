open Base
open Lwt.Syntax
open Infra

(* Entity module *)
module Entity = struct
  type t = Uuidm.t [@@deriving compare]

  let sexp_of_t t = Sexp.Atom (Uuidm.to_string t)

  type status =
    | Active
    | PendingDeletion
  [@@deriving compare]

  (* In-memory tracking of entity status *)
  let entities = Hashtbl.create (module struct
    type t = Uuidm.t
    let compare = Uuidm.compare
    let hash = Hashtbl.hash
    let sexp_of_t t = Sexp.Atom (Uuidm.to_string t)
  end)

  (* UUID generator *)
  let uuid () = 
    let state = Stdlib.Random.State.make_self_init () in
    Uuidm.v4_gen state ()

  (* Create a new entity *)
  let create () =
    let id = uuid () in
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let entity_id = Uuidm.to_string id in
      let* result = Db.exec 
        (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
          "INSERT INTO entities (id) VALUES (?)")
        entity_id
      in
      match result with
      | Ok () -> Lwt_result.return ()
      | Error e -> Lwt_result.fail e
    in
    let* result = Database.Pool.use db_operation in
    match result with
    | Ok () ->
        Hashtbl.set entities ~key:id ~data:Active;
        Lwt.return_ok id
    | Error e -> Lwt.return_error e

  (* Load all entities from the database *)
  let load_all () =
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let* result = Db.collect_list
        (Caqti_request.Infix.(Caqti_type.unit ->* Caqti_type.string)
          "SELECT id FROM entities")
        ()
      in
      match result with
      | Ok ids -> 
          let entity_ids = List.filter_map ids ~f:(fun id_str ->
            match Uuidm.of_string id_str with
            | Some id -> Some id
            | None -> 
                Stdio.eprintf "Invalid UUID format: %s\n" id_str;
                None
          ) in
          Lwt_result.return entity_ids
      | Error e -> Lwt_result.fail e
    in
    let* result = Database.Pool.use db_operation in
    match result with
    | Ok ids ->
        List.iter ids ~f:(fun id ->
          Hashtbl.set entities ~key:id ~data:Active);
        Lwt.return_ok ()
    | Error e -> Lwt.return_error e

  let destroy id =
    Hashtbl.set entities ~key:id ~data:PendingDeletion

  let exists id =
    match Hashtbl.find entities id with
    | Some Active -> true
    | _ -> false

  let get_pending_deletions () =
    Hashtbl.fold entities ~init:[] ~f:(fun ~key ~data acc ->
      match data with
      | PendingDeletion -> key :: acc
      | Active -> acc)

  let cleanup_deleted () =
    let deleted = get_pending_deletions () in
    List.iter deleted ~f:(fun id -> Hashtbl.remove entities id);
    deleted
end

(* Component interface *)
module type Component = sig
  type t [@@deriving yojson]
  val table_name : string
end

(* Component storage interface *)
module type ComponentStorage = sig
  type component
  val set : Entity.t -> component -> unit Lwt.t  (* Made Lwt.t for async *)
  val get : Entity.t -> component option Lwt.t   (* Made Lwt.t for async *)
  val remove : Entity.t -> unit Lwt.t            (* Made Lwt.t for async *)
  val all : unit -> (Entity.t * component) list Lwt.t
  val sync_to_db : unit -> unit Lwt.t
  val load_from_db : unit -> unit Lwt.t
  val clear_modified : unit -> unit
  val get_modified : unit -> Entity.t list
end

(* Functor to create component storage *)
module MakeComponentStorage (C : Component) : ComponentStorage 
  with type component = C.t = struct
  type component = C.t

  (* In-memory store *)
  let store = Hashtbl.create (module struct
    type t = Uuidm.t
    let compare = Uuidm.compare
    let hash = Hashtbl.hash
    let sexp_of_t t = Sexp.Atom (Uuidm.to_string t)
  end)
  
  (* Modified entities *)
  let modified = Hash_set.create (module struct
    type t = Uuidm.t
    let compare = Uuidm.compare
    let hash = Hashtbl.hash
    let sexp_of_t t = Sexp.Atom (Uuidm.to_string t)
  end)

  (* Mailbox for concurrency *)
  let mvar = Lwt_mvar.create_empty ()

  (* Process operations sequentially *)
  let rec process_loop () =
    let%lwt operation = Lwt_mvar.take mvar in
    let%lwt () = operation () in
    process_loop ()

  let () = Lwt.async (fun () -> process_loop ())

  (* Helper to enqueue operations with return value *)
  let enqueue_op op =
    let promise, resolver = Lwt.task () in
    let%lwt () = Lwt_mvar.put mvar (fun () ->
      let%lwt result = op () in
      Lwt.wakeup resolver result;
      Lwt.return_unit
    ) in
    promise

  let set entity component =
    enqueue_op (fun () ->
      if Entity.exists entity then begin
        Hashtbl.set store ~key:entity ~data:component;
        Hash_set.add modified entity;
      end;
      Lwt.return_unit
    )

  let get entity =
    enqueue_op (fun () ->
      Lwt.return (Hashtbl.find store entity)
    )

  let remove entity =
    enqueue_op (fun () ->
      Hashtbl.remove store entity;
      Hash_set.add modified entity;
      Lwt.return_unit
    )

  let all () =
    enqueue_op (fun () ->
      Lwt.return (Hashtbl.to_alist store)
    )

  let clear_modified () = Hash_set.clear modified
  
  let get_modified () = Hash_set.to_list modified

  (* Sync changes to database *)
  let sync_to_db () =
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let modified_list = get_modified () in
      let components = 
        List.filter_map modified_list ~f:(fun entity ->
          Option.map (Hashtbl.find store entity) ~f:(fun comp -> (entity, comp)))
      in
      
      (* Delete removed components *)
      let* _ = Lwt_list.iter_s (fun entity ->
        if not (Hashtbl.mem store entity) then
          let* result = Db.exec 
            (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
              ("DELETE FROM " ^ C.table_name ^ " WHERE entity_id = ?"))
            (Uuidm.to_string entity)
          in
          match result with
          | Ok () -> Lwt.return_unit
          | Error e -> 
              Stdio.eprintf "Failed to delete %s: %s\n" C.table_name (Caqti_error.show e);
              Lwt.return_unit
        else
          Lwt.return_unit
      ) modified_list in
      
      (* Update or insert components *)
      let* _ = Lwt_list.iter_s (fun (entity, comp) ->
        let json_str = comp |> [%to_yojson: C.t] |> Yojson.Safe.to_string in
        let entity_id = Uuidm.to_string entity in
        let* result = Db.exec 
          (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
            ("INSERT INTO " ^ C.table_name ^ " (entity_id, data) 
              VALUES (?, ?) 
              ON CONFLICT (entity_id) 
              DO UPDATE SET data = EXCLUDED.data"))
          (entity_id, json_str)
        in
        match result with
        | Ok () -> Lwt.return_unit
        | Error e -> 
            Stdio.eprintf "Failed to update %s: %s\n" C.table_name (Caqti_error.show e);
            Lwt.return_unit
      ) components in
      
      Lwt_result.return ()
    in
    
    let* result = Database.Pool.use db_operation in
    match result with
    | Ok () -> 
        clear_modified ();
        Lwt.return_unit 
    | Error e ->
        Stdio.eprintf "Failed to sync %s: %s\n" C.table_name (Error.to_string_hum e);
        Lwt.return_unit

  (* Load components from database *)
  let load_from_db () =
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let* result = Db.collect_list
        (Caqti_request.Infix.(Caqti_type.unit ->* Caqti_type.(t2 string string))
          ("SELECT entity_id, data FROM " ^ C.table_name))
        ()
      in
      match result with
      | Ok components -> Lwt_result.return components
      | Error e -> Lwt_result.fail e
    in
    
    let* result = Database.Pool.use db_operation in
    match result with
    | Ok components ->
        List.iter components ~f:(fun (entity_id_str, json_str) ->
          match Uuidm.of_string entity_id_str with
          | Some entity_id ->
              (match json_str |> Yojson.Safe.from_string |> [%of_yojson: C.t] with
              | Ok component -> Hashtbl.set store ~key:entity_id ~data:component
              | Error err -> 
                  Stdio.eprintf "Failed to parse %s: %s\n" C.table_name err)
          | None ->
              Stdio.eprintf "Invalid entity UUID: %s\n" entity_id_str);
        Lwt.return_unit
    | Error e ->
        Stdio.eprintf "Failed to load %s: %s\n" C.table_name (Error.to_string_hum e);
        Lwt.return_unit
end

(* Example component *)
(* module Position = struct
  type t = {
    x : float;
    y : float;
    z : float;
  } [@@deriving yojson]

  let table_name = "positions"  (* Each component gets its own table *)
end

module PositionStorage = MakeComponentStorage(Position) *)

open Components
module CharacterStorage = MakeComponentStorage(CharacterComponent)
module CharacterPositionStorage = MakeComponentStorage(CharacterPositionComponent)
module DescriptionStorage = MakeComponentStorage(DescriptionComponent)
module AreaStorage = MakeComponentStorage(AreaComponent)
module ExitStorage = MakeComponentStorage(ExitComponent)

(* World module *)
module World = struct
  (* System with priority *)
  type system = {
    priority: int;
    execute: unit -> unit Lwt.t;
  }

  (* Store systems in a sorted list (by priority) *)
  let systems : system list ref = ref []

  (* Register a system with a priority (lower numbers run first) *)
  let register_system ?(priority=100) execute =
    let new_system = { priority; execute } in
    (* Insert the system in the correct position based on priority *)
    let rec insert_sorted system = function
      | [] -> [system]
      | head :: tail when system.priority < head.priority -> 
          system :: head :: tail
      | head :: tail -> 
          head :: (insert_sorted system tail)
    in
    systems := insert_sorted new_system !systems

  (* Execute systems in their sorted order *)
  let step () =
    Lwt_list.iter_s (fun system -> system.execute ()) !systems

  let init () =
    let* result = Entity.load_all () in
    match result with
    | Ok () ->
        let* () = CharacterStorage.load_from_db () in
        let* () = CharacterPositionStorage.load_from_db () in
        let* () = DescriptionStorage.load_from_db () in
        let* () = AreaStorage.load_from_db () in
        let* () = ExitStorage.load_from_db () in
        (* Load other component storages here *)

        Lwt.return_ok ()
    | Error e -> Lwt.return_error e

  let sync_to_db () =
    Lwt.catch
      (fun () ->
        let* () = CharacterStorage.sync_to_db () in
        let* () = CharacterPositionStorage.sync_to_db () in
        let* () = DescriptionStorage.sync_to_db () in
        let* () = AreaStorage.sync_to_db () in
        let* () = ExitStorage.sync_to_db () in
        (* Sync other component storages here *)

        let deleted = Entity.cleanup_deleted () in
        if not (List.is_empty deleted) then
          let db_operation (module Db : Caqti_lwt.CONNECTION) =
            let* result = Lwt_list.fold_left_s (fun acc id ->
              let* r = Db.exec 
                (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
                  "DELETE FROM entities WHERE id = ?")
                (Uuidm.to_string id)
              in
              match r, acc with
              | Ok (), Ok () -> Lwt.return (Ok ())
              | Error e, _ -> Lwt.return (Error e)
              | _, Error e -> Lwt.return (Error e)
            ) (Ok ()) deleted in
            match result with
            | Ok () -> Lwt_result.return ()
            | Error e -> Lwt_result.fail e
          in
          let* result = Database.Pool.use db_operation in
          match result with
          | Ok () -> Lwt.return_unit
          | Error e ->
              Stdio.eprintf "Failed to delete entities: %s\n" (Error.to_string_hum e);
              Lwt.return_unit
        else
          Lwt.return_unit)
      (fun exn ->
        if String.equal (Exn.to_string exn) "End_of_file" then
          let () = Stdio.eprintf "Database sync error: End_of_file - Database connection may have been closed\n" in
          Lwt.return_unit
        else 
          let () = Stdio.eprintf "Database sync error: %s\n" (Exn.to_string exn) in
          Lwt.return_unit)
end