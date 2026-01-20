open Base
open Lwt.Syntax
open Qed_error

let calculate_and_update_stats (entity_id : Uuidm.t) : (unit, Qed_error.t) Result.t Lwt.t =
  let* core_stats_opt = Ecs.CoreStatsStorage.get entity_id in
  let* bonus_stats_opt = Ecs.BonusStatsStorage.get entity_id in
  let* active_bonuses_opt = Ecs.ActiveBonusesStorage.get entity_id in
  
  match core_stats_opt with
  | None ->
      Lwt.return_error (LogicError "Character has no core stats")
  | Some _core_stats ->
      (* Use bonuses if they exist, otherwise use an empty record *)
      let bonus_stats =
        Option.value bonus_stats_opt
          ~default:(Bonus_stats_component.empty (Uuidm.to_string entity_id))
      in

      let active_bonuses = Option.value active_bonuses_opt ~default:{ Components.ActiveBonusesComponent.entity_id = Uuidm.to_string entity_id; might=0; finesse=0; wits=0; grit=0; presence=0 } in

      (*
         Core attributes are DEFINED by active lore cards, not augmented by them.
         The system baseline assumes a minimal inherent value of 1 for each stat.
         Using the character's stored core stats here would double-count values that
         are already accounted for in `active_bonuses`. Therefore we derive the
         final core attributes as `1 + active_bonus`.
      *)
      let final_might = 1 + active_bonuses.might in
      let final_finesse = 1 + active_bonuses.finesse in
      let final_wits = 1 + active_bonuses.wits in
      let final_grit = 1 + active_bonuses.grit in
      let final_presence = 1 + active_bonuses.presence in

      (* Base stats from attributes *)
      let max_hp = final_grit * 10 in
      let max_ap = (final_wits + final_grit) * 5 in
      
      let health_component = Components.HealthComponent.{ entity_id = Uuidm.to_string entity_id; current = max_hp; max = max_hp } in
      let action_points_component = Components.ActionPointsComponent.{ entity_id = Uuidm.to_string entity_id; current = max_ap; max = max_ap } in
      
      let* () = Ecs.HealthStorage.set entity_id health_component in
      let* () = Ecs.ActionPointsStorage.set entity_id action_points_component in
      
      (* Calculate final derived stats by adding core attribute contribution and equipment bonuses *)
      let physical_power = final_might + bonus_stats.physical_power in
      let spell_power = final_presence + bonus_stats.spell_power in
      let accuracy = final_finesse + bonus_stats.accuracy in
      let evasion = final_finesse + bonus_stats.evasion in
      let armor = final_grit + bonus_stats.armor in
      let resolve = final_wits + bonus_stats.resolve in
      
      let derived_stats_component = Components.DerivedStatsComponent.{
        entity_id = Uuidm.to_string entity_id;
        physical_power;
        spell_power;
        accuracy;
        evasion;
        armor;
        resolve;
      } in
      
      let* () = Ecs.DerivedStatsStorage.set entity_id derived_stats_component in
      
      Lwt.return_ok ()