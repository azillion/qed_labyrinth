open Base

module Schema = struct
  let create_tables =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| CREATE TABLE IF NOT EXISTS users (
           id UUID PRIMARY KEY,
           username VARCHAR(255) NOT NULL UNIQUE,
           password_hash VARCHAR(255) NOT NULL,
           email VARCHAR(255) NOT NULL UNIQUE,
           created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
         ) |}
end

module Pool = struct
  type t = (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt_unix.Pool.t

  let create ?(max_size = 10) uri =
    let pool_config = Caqti_pool_config.create ~max_size () in
    Lwt.return (Caqti_lwt_unix.connect_pool ~pool_config uri)

  let use pool f = Caqti_lwt_unix.Pool.use f pool
end

let connect ?(pool_size = 10) config =
  let open Qed_config.Database in
  let uri = to_uri config in
  match%lwt Pool.create ~max_size:pool_size uri with
  | Error e ->
      Stdio.eprintf "Database connection error: %s\n" (Caqti_error.show e);
      Lwt.return_error (Error.of_string (Caqti_error.show e))
  | Ok pool -> (
      match%lwt
        Pool.use pool (fun (module C : Caqti_lwt.CONNECTION) ->
            C.exec Schema.create_tables ())
      with
      | Error e ->
          Stdio.eprintf "Schema creation error: %s\n" (Caqti_error.show e);
          Lwt.return_error (Error.of_string (Caqti_error.show e))
      | Ok () ->
          Stdio.printf "Database initialized successfully\n";
          Lwt.return_ok pool)
