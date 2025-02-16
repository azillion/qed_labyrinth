open Lwt.Syntax
open Infra
open Qed_error

type role =
  | Player
  | Admin
  | SuperAdmin

let role_of_string = function
  | "player" -> Player
  | "admin" -> Admin
  | "super admin" -> SuperAdmin
  | _ -> failwith "Invalid role"

let string_of_role = function
  | Player -> "player"
  | Admin -> "admin"
  | SuperAdmin -> "super admin"

type t = {
  id : string;
  username : string;
  password_hash : string;
  email : string;
  created_at : Ptime.t;
  deleted_at : Ptime.t option;
  token : string option;
  token_expires_at : Ptime.t option;
  role : role;
}

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

let hash_password password =
  Digestif.SHA256.digest_string password |> Digestif.SHA256.to_hex

let create ~username ~password ~email ~role =
  let id = Uuidm.to_string (uuid ()) in
  let password_hash = hash_password password in
  let created_at = Ptime_clock.now () in
  {
    id;
    username;
    password_hash;
    email;
    created_at;
    deleted_at = None;
    token = None;
    token_expires_at = None;
    role;
  }

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let user_type =
    let encode
        {
          id;
          username;
          password_hash;
          email;
          created_at;
          deleted_at;
          token;
          token_expires_at;
          role;
        } =
      Ok
        ( id,
          username,
          password_hash,
          email,
          created_at,
          deleted_at,
          token,
          token_expires_at,
          string_of_role role )
    in
    let decode
        ( id,
          username,
          password_hash,
          email,
          created_at,
          deleted_at,
          token,
          token_expires_at,
          role_str ) =
      match role_of_string role_str with
      | exception _ -> Error "Invalid role"
      | role ->
          Ok
            {
              id;
              username;
              password_hash;
              email;
              created_at;
              deleted_at;
              token;
              token_expires_at;
              role;
            }
    in
    let rep =
      t9 string string string string ptime (option ptime) (option string)
        (option ptime) string
    in
    custom ~encode ~decode rep

  let insert =
    (user_type ->. unit)
      {| INSERT INTO users (id, username, password_hash, email, created_at, deleted_at, token, token_expires_at, role)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) |}

  let find_by_id =
    (string ->? user_type)
      "SELECT * FROM users WHERE id = ? AND deleted_at IS NULL"

  let find_by_username =
    (string ->? user_type)
      "SELECT * FROM users WHERE username = ? AND deleted_at IS NULL"

  let find_by_email =
    (string ->? user_type)
      "SELECT * FROM users WHERE email = ? AND deleted_at IS NULL"

  let update_token =
    (t3 (option string) (option ptime) string ->. unit)
      {| UPDATE users 
         SET token = ?, token_expires_at = ?
         WHERE id = ? AND deleted_at IS NULL |}

  let soft_delete =
    (t2 ptime string ->. unit)
      {| UPDATE users 
         SET deleted_at = ?
         WHERE id = ? AND deleted_at IS NULL |}
end

let register ~username ~password ~email =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* existing_user = Db.find_opt Q.find_by_username username in
    match existing_user with
    | Error e -> Lwt_result.fail e
    | Ok (Some _) ->
        Lwt_result.return
          (`UsernameTaken : [ `UsernameTaken | `EmailTaken | `Success of t ])
    | Ok None -> (
        let* existing_email = Db.find_opt Q.find_by_email email in
        match existing_email with
        | Error e -> Lwt_result.fail e
        | Ok (Some _) -> Lwt_result.return `EmailTaken
        | Ok None -> (
            let user = create ~username ~password ~email ~role:Player in
            match%lwt Db.exec Q.insert user with
            | Error e -> Lwt_result.fail e
            | Ok () -> Lwt_result.return (`Success user)))
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok (`Success user) -> Lwt.return_ok user
  | Ok `UsernameTaken -> Lwt.return_error UsernameTaken
  | Ok `EmailTaken -> Lwt.return_error EmailTaken
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let authenticate ~username ~password =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* user_result = Db.find_opt Q.find_by_username username in
    match user_result with
    | Error e -> Lwt_result.fail e
    | Ok None ->
        Lwt_result.return
          (`UserNotFound : [ `UserNotFound | `Success of t | `InvalidPassword ])
    | Ok (Some user) ->
        let password_hash = hash_password password in
        if String.equal user.password_hash password_hash then
          Lwt_result.return (`Success user)
        else
          Lwt_result.return `InvalidPassword
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok (`Success user) -> Lwt.return_ok user
  | Ok `UserNotFound -> Lwt.return_error UserNotFound
  | Ok `InvalidPassword -> Lwt.return_error InvalidPassword
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let find_by_id id =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* user_result = Db.find_opt Q.find_by_id id in
    match user_result with
    | Error e -> Lwt_result.fail e
    | Ok result -> Lwt_result.return result
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok (Some user) -> Lwt.return_ok user
  | Ok None -> Lwt.return_error UserNotFound

let find_by_username username =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* user_result = Db.find_opt Q.find_by_username username in
    match user_result with
    | Error e -> Lwt_result.fail e
    | Ok result -> Lwt_result.return result
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
  | Ok (Some user) -> Lwt.return_ok user
  | Ok None -> Lwt.return_error UserNotFound

let update_token ~user_id ~token ~expires_at =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.exec Q.update_token (token, expires_at, user_id) with
    | Ok () -> Lwt_result.return ()
    | Error e -> Lwt_result.fail e
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok () -> Lwt.return_ok ()
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))

let soft_delete ~user_id =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let now = Ptime_clock.now () in
    match%lwt Db.exec Q.soft_delete (now, user_id) with
    | Ok () -> Lwt_result.return ()
    | Error e -> Lwt_result.fail e
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok () -> Lwt.return_ok ()
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
