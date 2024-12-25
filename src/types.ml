(* src/types.ml *)
open Base

type need = Hunger of float | Rest of float | Social of float
[@@deriving sexp, compare]

type memory = {
  event_type : string;
  significance : float; (* 0.0 to 1.0 *)
  timestamp : float;
  details : string;
}
[@@deriving sexp, compare]

type relationship = {
  trust : float; (* -1.0 to 1.0 *)
  debt : float; (* negative means they owe us *)
  loyalty : float; (* 0.0 to 1.0 *)
}
[@@deriving sexp, compare]

type agent_id = string [@@deriving sexp, compare]

type interaction =
  | Greet
  | Share of memory
  | Help of need
  | RequestHelp of need
[@@deriving sexp, compare]

module Room = struct
  type physical_item = { name : string; state : string }
  [@@deriving sexp, compare]

  type social_dynamic = {
    description : string;
    intensity : float; (* 0.0 to 1.0 *)
    participants : agent_id list;
  }
  [@@deriving sexp, compare]

  type t = {
    id : string;
    name : string;
    physical_state : physical_item list;
    social_dynamics : social_dynamic list;
    recent_events : memory list;
    present_agents : agent_id list;
  }
  [@@deriving sexp, compare]
end
