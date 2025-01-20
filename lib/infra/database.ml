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

  let create_characters_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS characters (
           id UUID PRIMARY KEY,
           user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
           name VARCHAR(255) NOT NULL,
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
  ]

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
        let%lwt indexes_result = exec_statements (module C) create_users_indexes in
        match indexes_result with
        | Error e -> Lwt.return_error e
        | Ok () ->
            let%lwt chars_result = C.exec create_characters_table () in
            match chars_result with
            | Error e -> Lwt.return_error e
            | Ok () -> exec_statements (module C) create_characters_indexes
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
