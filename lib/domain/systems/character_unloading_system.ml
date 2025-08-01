open Qed_error

module UnloadCharacterLogic : System.S with type event = Event.unload_character_from_ecs_payload = struct
  let name = "UnloadCharacterFromECS"
  type event = Event.unload_character_from_ecs_payload
  let event_type = function Event.UnloadCharacterFromECS e -> Some e | _ -> None

  let execute state _trace_id payload =
    let user_id = (payload : event).user_id in
    let character_id = payload.character_id in
    match Uuidm.of_string character_id with
    | None -> Lwt_result.fail InvalidCharacter
    | Some _entity_id ->
        let open Lwt.Syntax in
        (* Preserve the character's position so they respawn where they left off. *)
        (* let* () = Ecs.CharacterPositionStorage.remove entity_id in *)
        let* () = Lwt.return_unit in
        (match State.get_active_character state user_id with
         | Some current when String.equal (Uuidm.to_string current) character_id ->
             State.unset_active_character state ~user_id
         | _ -> ());
        Lwt_result.return ()
end
module UnloadCharacter = System.Make(UnloadCharacterLogic) 