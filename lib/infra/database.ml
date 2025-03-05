open Base

module Schema = struct
  let create_component_table name =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      (Printf.sprintf
         {| CREATE TABLE IF NOT EXISTS %s (
              entity_id UUID PRIMARY KEY REFERENCES entities(id),
              data JSONB NOT NULL
            ) |}
         name)
  
  let create_entities_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE TABLE IF NOT EXISTS entities ( id UUID PRIMARY KEY )"

  let create_users_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS users (
           id UUID PRIMARY KEY,
           username VARCHAR(255) NOT NULL UNIQUE,
           password_hash VARCHAR(255) NOT NULL,
           email VARCHAR(255) NOT NULL UNIQUE,
           created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
           deleted_at TIMESTAMP WITH TIME ZONE,
           token TEXT,
           token_expires_at TIMESTAMP WITH TIME ZONE,
           role VARCHAR(12) NOT NULL DEFAULT 'player' CHECK (role IN ('player', 'admin', 'super admin')),
           CONSTRAINT users_deleted_after_created CHECK (deleted_at IS NULL OR deleted_at > created_at)
         ) |}

  let create_users_indexes = [
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS users_deleted_at_idx ON users(deleted_at) WHERE deleted_at IS NULL";
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS users_username_idx ON users(username) WHERE deleted_at IS NULL";
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS users_email_idx ON users(email) WHERE deleted_at IS NULL";
  ]

  let create_areas_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS areas (
           id UUID PRIMARY KEY,
           name VARCHAR(255) NOT NULL,
           description TEXT NOT NULL,
           x INT,
           y INT,
           z INT,
           climate_elevation FLOAT,
           climate_temperature FLOAT,
           climate_moisture FLOAT,
           created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
         ) |}

  let create_areas_indexes = [
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS areas_coords_idx ON areas(x, y, z)";
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE UNIQUE INDEX IF NOT EXISTS areas_unique_coords_idx ON areas(x, y, z) WHERE x IS NOT NULL";
  ]

  let create_exits_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS exits (
           entity_id UUID PRIMARY KEY REFERENCES entities(id),
           from_entity UUID NOT NULL REFERENCES entities(id),
           to_entity UUID NOT NULL REFERENCES entities(id),
           direction VARCHAR(10),
           description TEXT,
           hidden BOOLEAN NOT NULL DEFAULT FALSE,
           locked BOOLEAN NOT NULL DEFAULT FALSE
         ) |}

  let create_starting_area_entry =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| INSERT INTO areas (id, name, description, x, y, z, climate_elevation, climate_temperature, climate_moisture)
         SELECT '00000000-0000-0000-0000-000000000000', 'The Ancient Oak Meadow', 
           'An ancient oak dominates the hillside, its twisted trunk rising from the earth in massive coils. The tree''s vast canopy spreads across the sky, its leaves catching rays of sunlight that pierce through gathering storm clouds above.
The meadow blooms with blue cornflowers and crimson poppies dotting the emerald grass.',
           0, 0, 0, 0.0, 0.0, 0.0
         WHERE NOT EXISTS (
           SELECT 1 FROM areas WHERE id = '00000000-0000-0000-0000-000000000000'
         ) |}

  let create_comm_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS communications (
           id UUID PRIMARY KEY,
           message_type VARCHAR(20) NOT NULL,
           sender_id UUID,
           content TEXT NOT NULL,
           area_id UUID REFERENCES areas(id),
           timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
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
        let* () = C.exec (create_component_table "characters") () in
        let* () = C.exec (create_component_table "character_positions") () in
        let* () = C.exec (create_component_table "descriptions") () in
        let* () = C.exec (create_component_table "healths") () in
        let* () = C.exec (create_component_table "manas") () in
        let* () = C.exec (create_component_table "levels") () in
        let* () = C.exec (create_component_table "messages") () in
        let* () = C.exec (create_component_table "senders") () in

        (* legacy tables *)
        let* () = C.exec create_users_table () in
        let* () = exec_statements (module C) create_users_indexes in
        let* () = C.exec create_areas_table () in
        let* () = exec_statements (module C) create_areas_indexes in
        let* () = C.exec create_exits_table () in
        let* () = C.exec create_starting_area_entry () in
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
        let%lwt result = Caqti_lwt_unix.Pool.use f pool in
        Lwt.return (Result.map_error ~f:(fun e -> Error.of_string (Caqti_error.show e)) result)

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