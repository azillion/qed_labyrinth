open Lwt.Syntax
open Qed_labyrinth_core

type t = {
  id : string;
  username : string;
  email : string;
  created_at : Ptime.t;
}

type error =
  | UserNotFound
  | InvalidPassword
  | UsernameTaken
  | EmailTaken
  | DatabaseError of string

(* Private type for internal use *)
type internal = {
  id : string;
  username : string;
  password_hash : string;
  email : string;
  created_at : Ptime.t;
  token : string option;
  token_expires_at : Ptime.t option;
}

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

let hash_password password =
  Digestif.SHA256.digest_string password |> Digestif.SHA256.to_hex

let create ~username ~password ~email =
  let id = Uuidm.to_string (uuid ()) in
  let password_hash = hash_password password in
  let created_at = Ptime_clock.now () in
  { id; username; password_hash; email; created_at; token = None; token_expires_at = None }

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let user_type =
    let encode { id; username; password_hash; email; created_at; token; token_expires_at } =
      Ok (id, username, password_hash, email, created_at, token, token_expires_at)
    in
    let decode (id, username, password_hash, email, created_at, token, token_expires_at) =
      Ok { id; username; password_hash; email; created_at; token; token_expires_at }
    in
    let rep = t7 string string string string ptime (option string) (option ptime) in
    custom ~encode ~decode rep

  let insert =
    (user_type ->. unit)
      {| INSERT INTO users (id, username, password_hash, email, created_at, token, token_expires_at)
         VALUES (?, ?, ?, ?, ?, ?, ?) |}

  let find_by_id = (string ->? user_type) "SELECT * FROM users WHERE id = ?"

  let find_by_username =
    (string ->? user_type) "SELECT * FROM users WHERE username = ?"

  let find_by_email =
    (string ->? user_type) "SELECT * FROM users WHERE email = ?"

  let update_token =
    (t3 (option string) (option ptime) string ->. unit)
      {| UPDATE users 
         SET token = ?, token_expires_at = ?
         WHERE id = ? |}
end

let to_public (user : internal) =
  { 
    id = user.id;
    username = user.username;
    email = user.email;
    created_at = user.created_at;
  }

let register ~username ~password ~email =
  let open Base in
      let db_operation (module Db : Caqti_lwt.CONNECTION) =
        let* existing_user = Db.find_opt Q.find_by_username username in
        match existing_user with
        | Error e -> Lwt_result.fail e
        | Ok (Some _) -> Lwt_result.return (`UsernameTaken : [ `UsernameTaken | `EmailTaken | `Success of t ])

        | Ok None -> 
            let* existing_email = Db.find_opt Q.find_by_email email in
            match existing_email with
            | Error e -> Lwt_result.fail e 
            | Ok (Some _) -> Lwt_result.return (`EmailTaken)
            | Ok None ->
                let user = create ~username ~password ~email in
                match%lwt Db.exec Q.insert user with
                | Error e -> Lwt_result.fail e
                | Ok () -> Lwt_result.return (`Success (to_public user))
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
       | Ok None -> Lwt_result.return (`UserNotFound : [ `UserNotFound | `Success of t | `InvalidPassword ])
       | Ok (Some user) -> 
            let password_hash = hash_password password in
            if String.equal user.password_hash password_hash then
              Lwt_result.return (`Success (to_public user))
            else
              Lwt_result.return (`InvalidPassword)
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
      | Ok (Some user) -> Lwt.return_ok (to_public user)
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
      | Ok (Some user) -> Lwt.return_ok (to_public user)
      | Ok None -> Lwt.return_error UserNotFound

let update_token ~user_id ~token ~expires_at =
  let open Base in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.exec Q.update_token (Some token, Some expires_at, user_id) with
    | Ok () -> Lwt_result.return ()
    | Error e -> Lwt_result.fail e
  in
  let* result = Database.Pool.use db_operation in
  match result with
  | Ok () -> Lwt.return_ok ()
  | Error e -> Lwt.return_error (DatabaseError (Error.to_string_hum e))
