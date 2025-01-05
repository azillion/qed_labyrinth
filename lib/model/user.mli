module User :
  sig
    type t = {
      id : string;
      username : string;
      password_hash : string;
      created_at : Ptime.t;
    }
  end

type t =
  User.t = {
  id : string;
  username : string;
  password_hash : string;
  created_at : Ptime.t;
}

module Q :
  sig
    val user : t Caqti_type.t
    val create_table : (unit, unit, [ `Zero ]) Caqti_request.t
    val insert_user : (t, unit, [ `Zero ]) Caqti_request.t
    val find_user_by_id : (string, t, [ `One | `Zero ]) Caqti_request.t
    val find_user_by_username : (string, t, [ `One | `Zero ]) Caqti_request.t
    val get_user_count : (unit, int, [ `One | `Zero ]) Caqti_request.t
  end

(* Database operations *)
val create_table :
  (module Caqti_lwt.CONNECTION) ->
  (unit, [> Caqti_error.call_or_retrieve ]) result Lwt.t
val insert_user :
  (module Caqti_lwt.CONNECTION) ->
  User.t -> (unit, [> Caqti_error.call_or_retrieve ]) result Lwt.t
val find_user_by_id :
  (module Caqti_lwt.CONNECTION) ->
  string -> (User.t option, [> Caqti_error.call_or_retrieve ]) result Lwt.t
val find_user_by_username :
  (module Caqti_lwt.CONNECTION) ->
  string -> (User.t option, [> Caqti_error.call_or_retrieve ]) result Lwt.t

(* User operations *)
val get_user_count : (module Caqti_lwt.CONNECTION) -> int Lwt.t
val hash_password : string -> string
val create : username:string -> password:string -> t
val verify_password : t -> string -> bool

(* Authentication operations *)
type auth_error = UserNotFound | InvalidPassword | UsernameTaken
val authenticate :
  (module Caqti_lwt.CONNECTION) ->
  username:string -> password:string -> (User.t, auth_error) result Lwt.t
val register :
  (module Caqti_lwt.CONNECTION) ->
  username:string -> password:string -> (t, auth_error) result Lwt.t
val username_exists : (module Caqti_lwt.CONNECTION) -> string -> bool Lwt.t
type user_view = { id : string; username : string; created_at : Ptime.t; }

val to_view : t -> user_view
val find_user_by_id_view :
  (module Caqti_lwt.CONNECTION) ->
  string ->
  (user_view option, [> Caqti_error.call_or_retrieve ]) result Lwt.t
