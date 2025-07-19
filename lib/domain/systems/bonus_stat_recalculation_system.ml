(* Bonus Stat Recalculation System *)
open Base
open Error_utils

(* Helper to parse stat bonuses from an item definition's properties *)
let parse_bonuses_from_json (json_opt : Yojson.Safe.t option) =
  let open Yojson.Safe.Util in
  match json_opt with
  | None -> Bonus_stats_component.empty "" (* Will be ignored *)
  | Some json ->
      {
        entity_id = ""; (* Will be ignored *)
        physical_power = json |> member "physical_power" |> to_int_option |> Option.value ~default:0;
        spell_power = json |> member "spell_power" |> to_int_option |> Option.value ~default:0;
        accuracy = json |> member "accuracy" |> to_int_option |> Option.value ~default:0;
        evasion = json |> member "evasion" |> to_int_option |> Option.value ~default:0;
        armor = json |> member "armor" |> to_int_option |> Option.value ~default:0;
        resolve = json |> member "resolve" |> to_int_option |> Option.value ~default:0;
      }

let recalculate_and_set_bonus_stats (entity_id : Uuidm.t) : (unit, Qed_error.t) Result.t Lwt.t =
  let%lwt equipment_opt = Ecs.EquipmentStorage.get entity_id in
  let equipment = Option.value equipment_opt ~default:(Equipment_component.empty (Uuidm.to_string entity_id)) in

  (* 1. Get all equipped item entity IDs *)
  let equipped_item_ids_str =
    List.filter_opt [ equipment.main_hand; equipment.off_hand; equipment.head; equipment.chest; equipment.legs; equipment.feet ]
  in
  let equipped_item_ids = List.filter_map equipped_item_ids_str ~f:Uuidm.of_string in

  (* 2. Get all ItemComponents for these IDs *)
  let%lwt item_comps = Lwt_list.filter_map_p Ecs.ItemStorage.get equipped_item_ids in

  (* 3. Get all Item Definitions for these items *)
  let def_ids = List.map item_comps ~f:(fun (comp:Components.ItemComponent.t) -> comp.item_definition_id) in
  let%lwt defs = Lwt_list.filter_map_p (fun id ->
    let%lwt res = Item_definition.find_by_id id in
    match res with Ok (Some def) -> Lwt.return_some def | _ -> Lwt.return_none
  ) def_ids in

  (* 4. Sum up all the bonuses *)
  let total_bonuses =
    List.fold defs ~init:(Bonus_stats_component.empty (Uuidm.to_string entity_id))
      ~f:(fun acc (def:Item_definition.t) ->
        let item_bonuses = parse_bonuses_from_json def.properties in
        { acc with
          physical_power = acc.physical_power + item_bonuses.physical_power;
          spell_power = acc.spell_power + item_bonuses.spell_power;
          accuracy = acc.accuracy + item_bonuses.accuracy;
          evasion = acc.evasion + item_bonuses.evasion;
          armor = acc.armor + item_bonuses.armor;
          resolve = acc.resolve + item_bonuses.resolve;
        })
  in

  (* 5. Set the final BonusStatsComponent for the character *)
  let%lwt () = Ecs.BonusStatsStorage.set entity_id total_bonuses in
  Lwt.return_ok ()

module BonusStatRecalculationLogic : System.S with type event = unit = struct
  let name = "BonusStatRecalculation"
  type event = unit
  let event_type _ = None (* Triggered by component change, not event payload *)

  let execute_for_entity (entity_id : Uuidm.t) =
    let open Lwt_result.Syntax in
    let* () = recalculate_and_set_bonus_stats entity_id in
    let* () = Character_stat_system.calculate_and_update_stats entity_id in
    Lwt_result.return ()

  let execute _state _trace_id _event =
    let modified_entities = Ecs.EquipmentStorage.get_modified () in

    Lwt_list.iter_p (fun entity_id ->
      let%lwt res = execute_for_entity entity_id in
      match res with
      | Ok () -> Lwt.return_unit
      | Error e ->
          let%lwt () = Infra.Monitoring.Log.error "Stat recalculation failed for entity"
            ~data:[("entity_id", Uuidm.to_string entity_id); ("error", Qed_error.to_string e)] () in
          Lwt.return_unit
    ) modified_entities |> wrap_ok
end

module BonusStatRecalculation = System.Make(BonusStatRecalculationLogic) 