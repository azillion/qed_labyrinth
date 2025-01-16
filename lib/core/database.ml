open Base

module Schema = struct
  let create_tables =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS users (
           id UUID PRIMARY KEY,
           username VARCHAR(255) NOT NULL UNIQUE,
           password_hash VARCHAR(255) NOT NULL,
           email VARCHAR(255) NOT NULL UNIQUE,
           created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
           token TEXT,
           token_expires_at TIMESTAMP WITH TIME ZONE
         ) |}
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
              C.exec Schema.create_tables ())
        with
        | Error e ->
            Stdio.eprintf "Schema creation error: %s\n" (Error.to_string_hum e);
            Lwt.return_error e
        | Ok () ->
            Stdio.printf "Database initialized successfully\n";
            Lwt.return_ok ())
end
