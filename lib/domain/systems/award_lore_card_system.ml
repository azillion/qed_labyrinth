open Base
open Infra
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

    (* Build prompts for LLM *)
    let system_prompt =
      "You are a narrative designer crafting collectible Lore Cards for a fantasy RPG." in
    let user_prompt =
      Printf.sprintf
        "Generate a short, flavorful title and a two-sentence description for a lore card based on this event: %s. Return the title on the first line and the description on the next."
        context
    in

    (* Call LLM *)
    let* llm_result =
      Llm_client.generate_with_openai ~system_prompt ~user_prompt
      |> Lwt.map (function
        | Ok txt -> Ok txt
        | Error err -> Error (Qed_error.ServerError err))
    in
    let text = llm_result in
    let lines = String.split_lines text in
    let title, description =
      match lines with
      | [] -> ("Untitled Lore", "A mysterious tale yet to be told.")
      | [only] -> (only, "")
      | first :: rest -> (first, String.concat ~sep:" " rest)
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