open Base

module Schema = struct
  let create_component_table name =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      (Printf.sprintf
         {| CREATE TABLE IF NOT EXISTS %s (
              entity_id TEXT PRIMARY KEY REFERENCES entities(id),
              data TEXT NOT NULL
            ) |}
         name)
  
  let create_entities_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE TABLE IF NOT EXISTS entities ( id TEXT PRIMARY KEY )"

  let create_users_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS users (
           id TEXT PRIMARY KEY,
           email TEXT NOT NULL UNIQUE,
           password_hash TEXT NOT NULL,
           created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
           deleted_at TIMESTAMP,
           token TEXT,
           token_expires_at TIMESTAMP,
           role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player', 'admin', 'super admin')),
           CONSTRAINT users_deleted_after_created CHECK (deleted_at IS NULL OR deleted_at > created_at)
         ) |}

  let create_users_indexes = [
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS users_deleted_at_idx ON users(deleted_at)";
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS users_email_idx ON users(email)";
  ]

  let create_areas_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS areas (
           id TEXT PRIMARY KEY,
           name TEXT NOT NULL,
           description TEXT NOT NULL,
           x INTEGER NOT NULL,
           y INTEGER NOT NULL,
           z INTEGER NOT NULL,
           climate_elevation REAL,
           climate_temperature REAL,
           climate_moisture REAL,
           created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
         ) |}

  let create_areas_indexes = [
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS areas_coords_idx ON areas(x, y, z)";
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE UNIQUE INDEX IF NOT EXISTS areas_unique_coords_idx ON areas(x, y, z)";
  ]

  let create_exits_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS exits (
           id TEXT PRIMARY KEY,
           from_area_id TEXT NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
           to_area_id TEXT NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
           direction TEXT NOT NULL,
           description TEXT,
           hidden BOOLEAN NOT NULL DEFAULT false,
           locked BOOLEAN NOT NULL DEFAULT false,
           UNIQUE(from_area_id, direction)
         ) |}

  let create_comm_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS communications (
           id TEXT PRIMARY KEY,
           message_type TEXT NOT NULL,
           sender_id TEXT,
           content TEXT NOT NULL,
           area_id TEXT REFERENCES areas(id),
           timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
         ) |}

  (* Helper to run a list of statements in sequence *)
  let exec_statements (module C : Caqti_lwt.CONNECTION) statements =
    let rec run_all = function
      | [] -> Lwt.return_ok ()
      | stmt :: rest ->
          let%lwt result = C.exec stmt () in
          match result with
          | Error e -> Lwt.return (Error e)
          | Ok () -> run_all rest
    in
    run_all statements

  (* Combined schema creation function *)
  let create_schema (module C : Caqti_lwt.CONNECTION) =
    let ( let* ) = Lwt_result.bind in
    
    Lwt.catch
      (fun () ->
        (* entity table *)
        let* () = C.exec create_entities_table () in

        (* component tables *)
        let* () = C.exec (create_component_table "character_positions") () in
        let* () = C.exec (create_component_table "derived_stats") () in
        let* () = C.exec (create_component_table "healths") () in
        let* () = C.exec (create_component_table "action_points") () in
        let* () = C.exec (create_component_table "manas") () in
        let* () = C.exec (create_component_table "levels") () in
        let* () = C.exec (create_component_table "messages") () in
        let* () = C.exec (create_component_table "senders") () in
        let* () = C.exec (create_component_table "items") () in
        let* () = C.exec (create_component_table "inventories") () in
        let* () = C.exec (create_component_table "item_positions") () in
        let* () = C.exec (create_component_table "unconscious_states") () in


        (* Tier-1 relational tables *)
        let* () = C.exec create_users_table () in
        let* () = C.exec create_areas_table () in
        let* () = C.exec create_exits_table () in
        let* () = C.exec (Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
          "CREATE TABLE IF NOT EXISTS characters (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, name TEXT NOT NULL UNIQUE, FOREIGN KEY(user_id) REFERENCES users(id))") () in
        let* () = C.exec (Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
          "CREATE TABLE IF NOT EXISTS character_core_stats (character_id TEXT PRIMARY KEY, might INTEGER NOT NULL, finesse INTEGER NOT NULL, wits INTEGER NOT NULL, grit INTEGER NOT NULL, presence INTEGER NOT NULL, FOREIGN KEY(character_id) REFERENCES characters(id))") () in
        let* () = C.exec (Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
          "CREATE TABLE IF NOT EXISTS item_definitions (id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE, description TEXT NOT NULL, item_type TEXT NOT NULL CHECK (item_type IN ('WEAPON', 'ARMOR', 'CONSUMABLE', 'MISC')), slot TEXT CHECK (slot IN ('MAIN_HAND', 'OFF_HAND', 'HEAD', 'CHEST', 'LEGS', 'FEET', 'NONE')), weight REAL NOT NULL DEFAULT 0.0, is_stackable BOOLEAN NOT NULL DEFAULT false, properties JSONB)") () in

        (* communications table used for chat and system messages *)
        let* () = C.exec create_comm_table () in

        Lwt.return_ok ())
      (fun _ -> failwith "Database error")
end

module Pool = struct
  type t = (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt_unix.Pool.t

  let pool_ref : t option ref = ref None
  let get () = !pool_ref
  let set p = pool_ref := Some p

  let make_pool ?(max_size = 10) uri =
    let pool_config = Caqti_pool_config.create ~max_size () in
    Caqti_lwt_unix.connect_pool ~pool_config uri

  let use f =
    match get () with
    | None -> Lwt.return_error (Error.of_string "Database pool not initialized")
    | Some pool -> 
        Lwt.catch
          (fun () ->
            let%lwt result = Caqti_lwt_unix.Pool.use f pool in
            Lwt.return (Result.map_error ~f:(fun e -> Error.of_string (Caqti_error.show e)) result))
          (fun exn ->
            let error_msg = Base.Exn.to_string exn in
            if String.equal error_msg "End_of_file" then
              Lwt.return_error (Error.of_string "Database connection closed unexpectedly")
            else
              Lwt.return_error (Error.of_string (Printf.sprintf "Database error: %s" error_msg)))

  let connect ?(max_size = 10) config =
    let open Config.Database in
    let uri = to_uri config in
    match make_pool ~max_size uri with
    | Error e ->
        Stdio.eprintf "Database connection error: %s\n" (Caqti_error.show e);
        Lwt.return_error (Error.of_string (Caqti_error.show e))
    | Ok pool -> (
        set pool;
        match%lwt
          use (fun (module C : Caqti_lwt.CONNECTION) ->
              Schema.create_schema (module C))
        with
        | Error e ->
            Stdio.eprintf "Schema creation error: %s\n" (Error.to_string_hum e);
            Lwt.return_error (Error.of_string (Error.to_string_hum e))
        | Ok () ->
            Stdio.printf "Database initialized successfully\n";
            Lwt.return_ok ())
end