open Lwt.Syntax

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
}

let uuid = Uuidm.v4_gen (Random.State.make_self_init ())

let hash_password password =
  Digestif.SHA256.digest_string password |> Digestif.SHA256.to_hex

let create ~username ~password ~email =
  let id = Uuidm.to_string (uuid ()) in
  let password_hash = hash_password password in
  let created_at = Ptime_clock.now () in
  { id; username; password_hash; email; created_at }

module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std

  let user_type =
    let encode { id; username; password_hash; email; created_at } =
      Ok (id, username, password_hash, email, created_at)
    in
    let decode (id, username, password_hash, email, created_at) =
      Ok { id; username; password_hash; email; created_at }
    in
    let rep = t5 string string string string ptime in
    custom ~encode ~decode rep

  let insert =
    (user_type ->. unit)
      {| INSERT INTO users (id, username, password_hash, email, created_at)
       VALUES (?, ?, ?, ?, ?) |}

  let find_by_id = (string ->? user_type) "SELECT * FROM users WHERE id = ?"

  let find_by_username =
    (string ->? user_type) "SELECT * FROM users WHERE username = ?"

  let find_by_email =
    (string ->? user_type) "SELECT * FROM users WHERE email = ?"
end

let to_public (user : internal) =
  { 
    id = user.id;
    username = user.username;
    email = user.email;
    created_at = user.created_at;
  }

let register ~(db : (module Caqti_lwt.CONNECTION)) ~username ~password ~email =
  let (module Db) = db in
  let open Lwt_result.Infix in
  let* existing_user =
    Db.find_opt Q.find_by_username username
    |> Lwt_result.map_error (fun e -> DatabaseError (Caqti_error.show e))
  in
  match existing_user with
  | Ok (Some _) -> Lwt.return_error UsernameTaken
  | Ok None -> (
      let* existing_email =
        Db.find_opt Q.find_by_email email
        |> Lwt_result.map_error (fun e -> DatabaseError (Caqti_error.show e))
      in
      match existing_email with
      | Ok (Some _) -> Lwt.return_error EmailTaken
      | Ok None ->
          let user = create ~username ~password ~email in
          Db.exec Q.insert user
          |> Lwt_result.map_error (fun e ->
                 DatabaseError (Caqti_error.show e))
          >|= fun () -> to_public user
      | Error e -> Lwt.return_error e)
  | Error e -> Lwt.return_error e

let authenticate ~(db : (module Caqti_lwt.CONNECTION)) ~username ~password =
  let (module Db) = db in
  let open Lwt_result.Infix in
  Db.find_opt Q.find_by_username username
  |> Lwt_result.map_error (fun e -> DatabaseError (Caqti_error.show e))
  >>= function
  | None -> Lwt.return_error UserNotFound
  | Some user ->
      let password_hash = hash_password password in
      if String.equal user.password_hash password_hash then
        Lwt.return_ok (to_public user)
      else
        Lwt.return_error InvalidPassword

let find_by_id ~(db : (module Caqti_lwt.CONNECTION)) id =
  let (module Db) = db in
  let open Lwt_result.Infix in
  Db.find_opt Q.find_by_id id
  |> Lwt_result.map_error (fun e -> DatabaseError (Caqti_error.show e))
  >|= Option.map to_public

let find_by_username ~(db : (module Caqti_lwt.CONNECTION)) username =
  let (module Db) = db in
  let open Lwt_result.Infix in
  Db.find_opt Q.find_by_username username
  |> Lwt_result.map_error (fun e -> DatabaseError (Caqti_error.show e))
  >|= Option.map to_public
