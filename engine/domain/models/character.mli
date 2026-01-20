open Base

type t = {
  id : string;
  user_id : string;
  name : string;
  proficiency_level : int;
  current_xp : int;
  saga_tier : int;
  current_ip : int;
}

val create : user_id:string -> name:string -> (t, Qed_error.t) Result.t Lwt.t

val find_by_id :
  string ->
  ?conn:(module Caqti_lwt.CONNECTION) ->
  unit ->
  (t option, Qed_error.t) Result.t Lwt.t

val find_all_by_user : user_id:string -> (t list, Qed_error.t) Result.t Lwt.t

val find_many_by_ids : string list -> (t list, Qed_error.t) Result.t Lwt.t

val update_progression : character_id:string -> xp_to_add:int -> ip_to_add:int -> (unit, Qed_error.t) Result.t Lwt.t