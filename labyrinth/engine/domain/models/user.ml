(**
  User model and data access.

  This module provides functions to interact with the `users` table in the database.
  It is responsible for data access operations like finding users by ID or username.
  
  IMPORTANT: This module does NOT handle authentication (password checking) or user
  registration. That logic is the sole responsibility of the API server.
  The engine trusts that the `userId` it receives in commands is authenticated.
*)

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
  password_hash : string;
  email : string;
  created_at : Ptime.t;
  deleted_at : Ptime.t option;
  token : string option;
  token_expires_at : Ptime.t option;
  role : role;
}



module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let user_type =
    let encode
        {
          id;
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
          email,
          password_hash,
          created_at,
          deleted_at,
          token,
          token_expires_at,
          string_of_role role )
    in
    let decode
        ( id,
          email,
          password_hash,
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
      t8 string string string ptime (option ptime) (option string)
        (option ptime) string
    in
    custom ~encode ~decode rep

  let find_by_id =
    (string ->? user_type)
      "SELECT * FROM users WHERE id = ? AND deleted_at IS NULL"

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

let find_by_email email =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    let* user_result = Db.find_opt Q.find_by_email email in
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
