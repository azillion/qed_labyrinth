open Qed_error

module UnloadCharacterLogic : System.S with type event = Event.unload_character_from_ecs_payload = struct
  let name = "character-unload"
  type event = Event.unload_character_from_ecs_payload
  let event_type = function Event.UnloadCharacterFromECS e -> Some e | _ -> None

  let execute state _trace_id payload =
    let user_id = (payload : event).user_id in
    let character_id = payload.character_id in
    match Uuidm.of_string character_id with
    | None -> Lwt_result.fail InvalidCharacter
    | Some entity_id ->
        let open Lwt.Syntax in
        let* () = Ecs.CharacterPositionStorage.remove entity_id in
        State.unset_active_character state ~user_id;
        Lwt_result.return ()
end
module UnloadCharacter = System.Make(UnloadCharacterLogic) 