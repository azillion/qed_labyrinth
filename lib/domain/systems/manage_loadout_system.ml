open Base
open Error_utils

(* Helper for auth copied similar to Character_sheet_system *)
let authenticate_character_action (state : State.t) (user_id : string) (character_id : string) =
  let open Lwt_result.Syntax in
  match Uuidm.of_string character_id with
  | None -> Lwt_result.fail Qed_error.InvalidCharacter
  | Some char_uuid -> (
      match State.get_active_character state user_id with
      | Some active_uuid when Uuidm.equal active_uuid char_uuid -> Lwt_result.return char_uuid
      | _ ->
          let* () = wrap_ok (State.enqueue state (Event.ActionFailed { user_id; reason = "You cannot control that character." })) in
          Lwt_result.fail (Qed_error.LogicError "Character action authorization failed"))

(* ---------------- Activate Logic ---------------- *)
module ActivateLoreCardLogic : System.S with type event = Event.activate_lore_card_payload = struct
  let name = "ActivateLoreCard"
  type event = Event.activate_lore_card_payload
  let event_type = function Event.ActivateLoreCard e -> Some e | _ -> None

  let execute state trace_id (p : Event.activate_lore_card_payload) =
    let open Lwt_result.Syntax in
    let { Event.user_id = user_id; character_id; card_instance_id } : Event.activate_lore_card_payload = p in

    (* Fetch character record for power budget calculations *)
    let* char_opt = Character.find_by_id character_id in
    let* char_record = match char_opt with
      | Some c -> Lwt_result.return c
      | None -> Lwt_result.fail Qed_error.CharacterNotFound
    in
    let power_budget = Game_balance.power_budget_for_level char_record.proficiency_level in

    (* Sum current active card costs *)
    let* active_cards = Lore_card.find_active_instances_by_character_id character_id in
    let rec sum_cost acc = function
      | [] -> Lwt_result.return acc
      | (card : Lore_card.Instance.t)::rest ->
          let* tmpl_opt = Lore_card.find_template_by_id card.template_id in
          (match tmpl_opt with
          | None -> sum_cost acc rest
          | Some tmpl -> sum_cost (acc + tmpl.power_cost) rest)
    in
    let* current_cost = sum_cost 0 active_cards in
    (* Power cost of card to activate *)
    let* instances = Lore_card.find_instances_by_character_id character_id in
    let new_card_inst_opt = List.find instances ~f:(fun (ci : Lore_card.Instance.t) -> String.equal ci.id card_instance_id) in
    let* new_card_inst = match new_card_inst_opt with
      | None -> Lwt_result.fail (Qed_error.LogicError "Card instance not found")
      | Some c -> Lwt_result.return c
    in
    let* tmpl_opt = Lore_card.find_template_by_id new_card_inst.template_id in
    let* tmpl = match tmpl_opt with | None -> Lwt_result.fail (Qed_error.LogicError "Card template missing") | Some t -> Lwt_result.return t in
    if current_cost + tmpl.power_cost > power_budget then
      let* () = wrap_ok (State.enqueue ?trace_id state (Event.ActionFailed { user_id; reason = "Not enough Power Budget" })) in
      Lwt_result.return ()
    else
      let* () = Lore_card.set_active_status ~instance_id:card_instance_id ~is_active:true in
      let* () = wrap_ok (State.enqueue ?trace_id state (Event.LoadoutChanged { character_id })) in
      Lwt_result.return ()
end

module ActivateLoreCard = System.Make(ActivateLoreCardLogic)

(* ---------------- Deactivate Logic ---------------- *)
module DeactivateLoreCardLogic : System.S with type event = Event.deactivate_lore_card_payload = struct
  let name = "DeactivateLoreCard"
  type event = Event.deactivate_lore_card_payload
  let event_type = function Event.DeactivateLoreCard e -> Some e | _ -> None

  let execute state trace_id (p : Event.deactivate_lore_card_payload) =
    let open Lwt_result.Syntax in
    let { Event.user_id = user_id; character_id; card_instance_id } : Event.deactivate_lore_card_payload = p in
    let* _ = authenticate_character_action state user_id character_id in
    let* () = Lore_card.set_active_status ~instance_id:card_instance_id ~is_active:false in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.LoadoutChanged { character_id })) in
    Lwt_result.return ()
end

module DeactivateLoreCard = System.Make(DeactivateLoreCardLogic) 