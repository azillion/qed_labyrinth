open Base

let uri = Uri.of_string "sqlite3:qed.db"

module T = struct
  include Caqti_type
end

(* database queries *)
module Schema = struct
  let create_tables =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {|
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE
        );
        CREATE TABLE IF NOT EXISTS characters (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          user_id INTEGER NOT NULL
        );
      |}
end

(* handle db errors *)
let or_error m =
  Result.map_error ~f:(fun e -> Error.of_string (Caqti_error.show e)) m

(* initialize connection *)
let connect () =
  match%lwt Caqti_lwt_unix.connect uri with
  | Ok connection -> (
      let (module C : Caqti_lwt.CONNECTION) = connection in
      let open Lwt.Syntax in
      let* start_res = C.start () in
      match start_res with
      | Error e -> Lwt.return_error (Error.of_string (Caqti_error.show e))
      | Ok () ->
          let* exec_res = C.exec Schema.create_tables () in
          match exec_res with
          | Error e -> Lwt.return_error (Error.of_string (Caqti_error.show e))
          | Ok () ->
              let* commit_res = C.commit () in
              match commit_res with
              | Ok () -> Lwt.return_ok connection
              | Error e -> Lwt.return_error (Error.of_string (Caqti_error.show e)))
  | Error e -> Lwt.return_error (Error.of_string (Caqti_error.show e))
