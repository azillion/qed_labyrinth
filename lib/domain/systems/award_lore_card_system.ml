open Error_utils

module AwardLoreCardLogic : System.S with type event = Event.award_lore_card_payload = struct
  let name = "AwardLoreCard"
  type event = Event.award_lore_card_payload

  let event_type = function
    | Event.AwardLoreCard e -> Some e
    | _ -> None

  let execute state trace_id ({ character_id; template_id; context } : event) =
    let open Lwt_result.Syntax in
    (* Fetch character record to get user_id *)
    let* char_opt = Character.find_by_id character_id in
    let* char_rec = match char_opt with
      | Some c -> Lwt_result.return c
      | None -> Lwt_result.fail Qed_error.CharacterNotFound
    in
    let user_id = char_rec.user_id in

    (* Context string is used directly by the LLM helper *)

    (* Ask the LLM for structured metadata; if it fails, use safe defaults. *)
    let* (title, description) =
      Lore_card_generator.generate_metadata ~context
    in

    (* Persist lore card instance *)
    let* _card =
      Lore_card.create_instance ~character_id ~template_id ~title ~description
    in

    (* Notify client *)
    let* () =
      wrap_ok
        (State.enqueue ?trace_id state
           (Event.LoreCardAwarded { user_id; card_title = title }))
    in
    Lwt_result.return ()
end

module AwardLoreCard = System.Make (AwardLoreCardLogic) 