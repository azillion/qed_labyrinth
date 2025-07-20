(** The required experience points to reach a given proficiency level. *)
val xp_for_level : int -> int

(** The Power Budget granted at a given proficiency level. *)
val power_budget_for_level : int -> int

(** The required influence points to reach a given saga tier. *)
val ip_for_tier : int -> int 