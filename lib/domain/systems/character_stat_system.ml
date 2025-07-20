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
  | Some core_stats ->
      (* Use bonuses if they exist, otherwise use an empty record *)
      let bonus_stats =
        Option.value bonus_stats_opt
          ~default:(Bonus_stats_component.empty (Uuidm.to_string entity_id))
      in

      let active_bonuses = Option.value active_bonuses_opt ~default:{ Components.ActiveBonusesComponent.entity_id = Uuidm.to_string entity_id; might=0; finesse=0; wits=0; grit=0; presence=0 } in

      (* Combine core attributes with active bonuses from lore cards *)
      let total_might = core_stats.might + active_bonuses.might in
      let total_finesse = core_stats.finesse + active_bonuses.finesse in
      let total_wits = core_stats.wits + active_bonuses.wits in
      let total_grit = core_stats.grit + active_bonuses.grit in
      let total_presence = core_stats.presence + active_bonuses.presence in

      (* Base stats from attributes *)
      let max_hp = total_grit * 10 in
      let max_ap = (total_wits + total_grit) * 5 in
      
      let health_component = Components.HealthComponent.{ entity_id = Uuidm.to_string entity_id; current = max_hp; max = max_hp } in
      let action_points_component = Components.ActionPointsComponent.{ entity_id = Uuidm.to_string entity_id; current = max_ap; max = max_ap } in
      
      let* () = Ecs.HealthStorage.set entity_id health_component in
      let* () = Ecs.ActionPointsStorage.set entity_id action_points_component in
      
      (* Calculate final derived stats by adding core attribute contribution and equipment bonuses *)
      let physical_power = total_might + bonus_stats.physical_power in
      let spell_power = total_presence + bonus_stats.spell_power in
      let accuracy = total_finesse + bonus_stats.accuracy in
      let evasion = total_finesse + bonus_stats.evasion in
      let armor = total_grit + bonus_stats.armor in
      let resolve = total_wits + bonus_stats.resolve in
      
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