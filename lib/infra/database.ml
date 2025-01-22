open Base

module Schema = struct
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
           from_area_id UUID NOT NULL REFERENCES areas(id),
           to_area_id UUID NOT NULL REFERENCES areas(id),
           direction VARCHAR(10) CHECK (direction IN ('north', 'south', 'east', 'west', 'up', 'down')),
           description TEXT,
           hidden BOOLEAN NOT NULL DEFAULT FALSE,
           locked BOOLEAN NOT NULL DEFAULT FALSE,
           PRIMARY KEY (from_area_id, direction)
         ) |}

  let create_characters_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS characters (
           id UUID PRIMARY KEY,
           user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
           name VARCHAR(255) NOT NULL,
           location_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES areas(id),
           created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
           deleted_at TIMESTAMP WITH TIME ZONE,
           UNIQUE(user_id, name),
           CONSTRAINT characters_deleted_after_created CHECK (deleted_at IS NULL OR deleted_at > created_at)
         ) |}

  let create_characters_indexes = [
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS characters_user_id_idx ON characters(user_id) WHERE deleted_at IS NULL";
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS characters_name_idx ON characters(name) WHERE deleted_at IS NULL";
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      "CREATE INDEX IF NOT EXISTS characters_location_idx ON characters(location_id) WHERE deleted_at IS NULL";
  ]

  (* make sure there is a starting area entry, if not, create it *)
  let create_starting_area_entry =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| WITH area_inserts AS (
         INSERT INTO areas (id, name, description, x, y, z)
         SELECT '00000000-0000-0000-0000-000000000000', 'The Ancient Oak Meadow', 'An ancient oak dominates the hillside, its twisted trunk rising from the earth in massive coils. The tree''s vast canopy spreads across the sky, its leaves catching rays of sunlight that pierce through gathering storm clouds above.
The meadow blooms with blue cornflowers and crimson poppies dotting the emerald grass. Misty mountains rise to the east, their peaks shrouded in clouds. Well-worn paths lead north and south along the hillside, while the western path curves down toward a valley.', 0, 0, 0
         WHERE NOT EXISTS (
           SELECT 1 FROM areas WHERE id = '00000000-0000-0000-0000-000000000000'
         )
         RETURNING id
       ),
       second_area AS (
         INSERT INTO areas (id, name, description, x, y, z)
         SELECT '11111111-1111-1111-1111-111111111111', 'The Mountain Path', 'The ground rises steadily toward the mountains, the grass giving way to loose shale and hardy mountain flowers. Mist clings to the higher elevations, swirling in slow eddies around the rocky outcrops.
The ancient oak remains visible to the west, while the path splits around weathered boulders. The northern fork climbs steeply into the mountains, while the southern route descends into a sheltered vale.', 1, 0, 0
         WHERE NOT EXISTS (
           SELECT 1 FROM areas WHERE id = '11111111-1111-1111-1111-111111111111'
         )
         RETURNING id
       )
       INSERT INTO exits (from_area_id, to_area_id, direction, description)
       SELECT a1.id, a2.id, 'east', 'The path leads east toward the mountains.'
       FROM (SELECT id FROM areas WHERE id = '00000000-0000-0000-0000-000000000000') a1,
            (SELECT id FROM areas WHERE id = '11111111-1111-1111-1111-111111111111') a2
       WHERE NOT EXISTS (
         SELECT 1 FROM exits WHERE from_area_id = a1.id AND direction = 'east'
       )
       UNION ALL
       SELECT a2.id, a1.id, 'west', 'The path leads west back to the ancient oak.'
       FROM (SELECT id FROM areas WHERE id = '00000000-0000-0000-0000-000000000000') a1,
            (SELECT id FROM areas WHERE id = '11111111-1111-1111-1111-111111111111') a2
       WHERE NOT EXISTS (
         SELECT 1 FROM exits WHERE from_area_id = a2.id AND direction = 'west'
       ) |}

       let create_comm_table =
        Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
          {| CREATE TABLE IF NOT EXISTS communications (
               id UUID PRIMARY KEY,
               message_type VARCHAR(20) NOT NULL,
               sender_id UUID REFERENCES characters(id),
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
    let%lwt users_result = C.exec create_users_table () in
    match users_result with
    | Error e -> Lwt.return_error e
    | Ok () ->
        let%lwt users_indexes_result = exec_statements (module C) create_users_indexes in
        match users_indexes_result with
        | Error e -> Lwt.return_error e
        | Ok () ->
            let%lwt areas_result = C.exec create_areas_table () in
            match areas_result with
            | Error e -> Lwt.return_error e
            | Ok () ->
                let%lwt areas_indexes_result = exec_statements (module C) create_areas_indexes in
                match areas_indexes_result with
                | Error e -> Lwt.return_error e
                | Ok () ->
                    let%lwt exits_result = C.exec create_exits_table () in
                    match exits_result with
                    | Error e -> Lwt.return_error e
                    | Ok () ->
                        let%lwt chars_result = C.exec create_characters_table () in
                        match chars_result with
                        | Error e -> Lwt.return_error e
                        | Ok () ->
                            let%lwt chars_indexes_result = exec_statements (module C) create_characters_indexes in
                            match chars_indexes_result with
                            | Error e -> Lwt.return_error e
                            | Ok () ->
                                let%lwt starting_area_result = C.exec create_starting_area_entry () in
                                match starting_area_result with
                                | Error e -> Lwt.return_error e
                                | Ok () -> 
                                    let%lwt comm_result = C.exec create_comm_table () in
                                    match comm_result with
                                    | Error e -> Lwt.return_error e
                                    | Ok () -> Lwt.return_ok ()
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