type role =
  | Player
  | Admin
  | SuperAdmin

val role_of_string : string -> role
val string_of_role : role -> string

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


val find_by_id : string -> (t, Qed_error.t) result Lwt.t
val find_by_username : string -> (t, Qed_error.t) result Lwt.t

val update_token :
  user_id:string ->
  token:string option ->
  expires_at:Ptime.t option ->
  (unit, Qed_error.t) result Lwt.t

val soft_delete : user_id:string -> (unit, Qed_error.t) result Lwt.t

module Q : sig
  val find_by_id : (string, t, [ `Zero | `One ]) Caqti_request.t
  (* Maybe other queries if needed *)
end
