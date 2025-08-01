open Base
open Error_utils
module AB = Components.ActiveBonusesComponent

module RecalculateStatsLogic : System.S with type event = Event.loadout_changed_payload = struct
  let name = "RecalculateStats"
  type event = Event.loadout_changed_payload
  let event_type = function Event.LoadoutChanged e -> Some e | _ -> None

  let execute state trace_id ({ character_id } : event) =
    let open Lwt_result.Syntax in
    (* Resolve character entity UUID and user_id *)
    let* char_opt = Character.find_by_id character_id () in
    let* character = match char_opt with
      | Some c -> Lwt_result.return c
      | None -> Lwt_result.fail Qed_error.CharacterNotFound
    in
    let user_id = character.user_id in
    let entity_uuid =
      match Uuidm.of_string character_id with
      | Some id -> id
      | None -> Uuidm.nil (* should not happen *)
    in

    (* 1. Fetch active lore cards with templates (efficient) *)
    let* active_pairs = Lore_card.find_active_instances_with_templates character_id in

    (* 2 & 3. Sum bonuses *)
    let empty_bonus () = AB.{ entity_id = character_id; might=0; finesse=0; wits=0; grit=0; presence=0 } in
    let sum_bonus (acc : AB.t) (tmpl : Lore_card.Template.t) =
      let module T = Lore_card.Template in
      let add (acc : AB.t) type_opt value_opt =
        match (type_opt, value_opt) with
        | Some t, Some v -> (
            match String.lowercase t with
            | "might" -> { acc with might = acc.might + v }
            | "finesse" -> { acc with finesse = acc.finesse + v }
            | "wits" -> { acc with wits = acc.wits + v }
            | "grit" -> { acc with grit = acc.grit + v }
            | "presence" -> { acc with presence = acc.presence + v }
            | _ -> acc)
        | _ -> acc
      in
      let acc1 = add acc tmpl.T.bonus_1_type tmpl.T.bonus_1_value in
      let acc2 = add acc1 tmpl.T.bonus_2_type tmpl.T.bonus_2_value in
      let acc3 = add acc2 tmpl.T.bonus_3_type tmpl.T.bonus_3_value in
      acc3
    in
    let* final_bonus =
      let acc = Base.List.fold active_pairs ~init:(empty_bonus ()) ~f:(fun acc (_i, t) -> sum_bonus acc t) in
      Lwt_result.return acc
    in

    (* 5. Save ActiveBonusesComponent *)
    let* () = wrap_ok (Ecs.ActiveBonusesStorage.set entity_uuid final_bonus) in

    (* 5b. Persist CoreStatsComponent as baseline 1 + bonuses. The stored
       core stats are not meant to accumulate over time; they should always
       represent the final attribute values shown to the player. *)
          let open Components in
          let updated_core = CoreStatsComponent.{
      entity_id = character_id;
      might     = 1 + final_bonus.might;
      finesse   = 1 + final_bonus.finesse;
      wits      = 1 + final_bonus.wits;
      grit      = 1 + final_bonus.grit;
      presence  = 1 + final_bonus.presence;
          } in
    let* () = wrap_ok (Ecs.CoreStatsStorage.set entity_uuid updated_core) in

    (* 6. Recalculate final stats *)
    let* () = Character_stat_system.calculate_and_update_stats entity_uuid in

    (* 7. Push updated sheet to client *)
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.RequestCharacterSheet { user_id; character_id })) in
    Lwt_result.return ()
end

module RecalculateStats = System.Make (RecalculateStatsLogic) 