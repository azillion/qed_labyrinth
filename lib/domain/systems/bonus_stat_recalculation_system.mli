open Base

(**
  Recalculates the total stat bonuses from a character's equipped items
  and updates their BonusStatsComponent. This function is the single source
  of truth for equipment stat aggregation.
  @param entity_id The UUID of the character entity.
*)
val recalculate_and_set_bonus_stats : Uuidm.t -> (unit, Qed_error.t) Result.t Lwt.t

(**
  A system that reactively triggers bonus and derived stat recalculation
  when a character's equipment changes.
*)
module BonusStatRecalculation : sig
  val handle : State.t -> string option -> Event.t option -> (unit, Qed_error.t) Result.t Lwt.t
end 