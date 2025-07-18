open Base

module CoreStats : sig
  type t = {
    character_id : string;
    might : int;
    finesse : int;
    wits : int;
    grit : int;
    presence : int;
  }
end

type t = {
  id : string;
  user_id : string;
  name : string;
  core_stats : CoreStats.t;
}

val create : user_id:string -> name:string -> might:int -> finesse:int -> wits:int -> grit:int -> presence:int -> (t, Qed_error.t) Result.t Lwt.t

val find_by_id : string -> (t option, Qed_error.t) Result.t Lwt.t

val find_all_by_user : user_id:string -> (t list, Qed_error.t) Result.t Lwt.t

val find_many_by_ids : string list -> (t list, Qed_error.t) Result.t Lwt.t