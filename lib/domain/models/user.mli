type t = {
  id : string;
  username : string;
  password_hash : string;
  email : string;
  created_at : Ptime.t;
  deleted_at : Ptime.t option;
  token : string option;
  token_expires_at : Ptime.t option;
}

type error =
  | UserNotFound
  | InvalidPassword
  | UsernameTaken
  | EmailTaken
  | DatabaseError of string

val register :
  username:string -> password:string -> email:string -> (t, error) result Lwt.t

val authenticate : username:string -> password:string -> (t, error) result Lwt.t
val find_by_id : string -> (t, error) result Lwt.t
val find_by_username : string -> (t, error) result Lwt.t

val update_token :
  user_id:string ->
  token:string option ->
  expires_at:Ptime.t option ->
  (unit, error) result Lwt.t

val soft_delete : user_id:string -> (unit, error) result Lwt.t

module Q : sig
  val find_by_id : (string, t, [ `Zero | `One ]) Caqti_request.t
  (* Maybe other queries if needed *)
end
