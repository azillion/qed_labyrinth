open Base
open Lwt.Syntax
open Qed_error

let calculate_and_update_stats (entity_id : Uuidm.t) : (unit, Qed_error.t) Result.t Lwt.t =
  let* core_stats_opt = Ecs.CoreStatsStorage.get entity_id in
  match core_stats_opt with
  | Some core_stats ->
      let max_hp = core_stats.grit * 10 in
      let max_ap = (core_stats.wits + core_stats.grit) * 5 in
      
      let health_component = Components.HealthComponent.{ entity_id = Uuidm.to_string entity_id; current = max_hp; max = max_hp } in
      let action_points_component = Components.ActionPointsComponent.{ entity_id = Uuidm.to_string entity_id; current = max_ap; max = max_ap } in
      
      let* () = Ecs.HealthStorage.set entity_id health_component in
      let* () = Ecs.ActionPointsStorage.set entity_id action_points_component in
      
      let physical_power = core_stats.might in
      let spell_power = core_stats.presence in
      let accuracy = core_stats.finesse in
      let evasion = core_stats.finesse in
      let armor = core_stats.grit in
      let resolve = core_stats.wits in
      
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
  | None ->
      Lwt.return_error (LogicError "Character has no core stats")