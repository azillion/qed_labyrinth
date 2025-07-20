open Error_utils

module AwardExperienceLogic : System.S with type event = Event.award_experience_payload = struct
  let name = "AwardExperience"
  type event = Event.award_experience_payload

  let event_type = function
    | Event.AwardExperience e -> Some e
    | _ -> None

  let execute (state : State.t) trace_id ({ Event.character_id; xp; ip } : event) =
    let open Lwt_result.Syntax in
    (* Update character progression in database *)
    let* () = Character.update_progression ~character_id ~xp_to_add:xp ~ip_to_add:ip in
    (* Enqueue follow-up event to notify other systems *)
    let* () =
      wrap_ok
        (State.enqueue ?trace_id state
           (Event.PlayerGainedExperience { character_id }))
    in
    Lwt_result.return ()
end

module AwardExperience = System.Make (AwardExperienceLogic) 