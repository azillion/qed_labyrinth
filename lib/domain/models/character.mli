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

val create : user_id:string -> name:string -> (t, Qed_error.t) Result.t Lwt.t

val find_by_id : string -> (t option, Qed_error.t) Result.t Lwt.t