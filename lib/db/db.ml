open Base

module T = struct
  include Caqti_type

  (* Basic user type for auth *)
  let user_info =
    let encode (username, pass_hash) = Ok (username, pass_hash)
    and decode (username, pass_hash) = Ok (username, pass_hash) in
    custom ~encode ~decode (t2 string string)
  (* Changed from tup2 to t2 *)
end

(* Database queries *)
module Q = struct
  let create_users_table =
    Caqti_request.Infix.(Caqti_type.unit ->. Caqti_type.unit)
      {| 
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL
    )
  |}

  let add_user =
    Caqti_request.Infix.(T.user_info ->! Caqti_type.unit)
      "INSERT INTO users (username, password_hash) VALUES (?, ?)"

  let get_user =
    Caqti_request.Infix.(T.user_info ->? T.user_info)
      "SELECT username, password_hash FROM users WHERE username = ?"
end

(* Handle DB errors *)
let or_error m =
  m |> Result.map_error ~f:(fun e -> Error.of_string (Caqti_error.show e))

(* Initialize connection *)
let connect () =
  let uri = Uri.of_string "sqlite3:qed.db" in
  match%lwt Caqti_lwt_unix.connect uri with
  | Ok connection -> (
      let (module C : Caqti_lwt.CONNECTION) = connection in
      let%lwt res = C.exec Q.create_users_table () in
      match res with
      | Ok () -> Lwt.return_ok connection
      | Error e -> Lwt.return_error (Error.of_string (Caqti_error.show e)))
  | Error e -> Lwt.return_error (Error.of_string (Caqti_error.show e))
