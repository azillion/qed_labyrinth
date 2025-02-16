type t = {
  id : string;
  user_id : string;
  name : string;
  location_id : string;
  created_at : Ptime.t;
  deleted_at : Ptime.t option;
}

val create : user_id:string -> name:string -> (t, Qed_error.t) result Lwt.t
val find_by_id : string -> (t, Qed_error.t) result Lwt.t

val find_by_user_and_name :
  user_id:string -> name:string -> (t, Qed_error.t) result Lwt.t

val find_all_by_user : user_id:string -> (t list, Qed_error.t) result Lwt.t
val soft_delete : character_id:string -> (unit, Qed_error.t) result Lwt.t

val move :
  character_id:string ->
  direction:Area.direction ->
  (string, Qed_error.t) result Lwt.t
