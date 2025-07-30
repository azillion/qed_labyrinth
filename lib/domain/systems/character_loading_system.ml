open Base
open Qed_error
open Error_utils

module LoadCharacterLogic : System.S with type event = Event.load_character_into_ecs_payload = struct
  let name = "LoadCharacterIntoECS"
  type event = Event.load_character_into_ecs_payload
  let event_type = function Event.LoadCharacterIntoECS e -> Some e | _ -> None

  let execute state trace_id payload =
    (* let user_id = (payload : event).user_id in *)
    let character_id = (payload : event).character_id in
    let open Lwt_result.Syntax in
    let* character_opt = Character.find_by_id character_id () in
    match character_opt with
    | None -> Lwt_result.fail CharacterNotFound
    | Some character ->
        match Uuidm.of_string character.id with
        | None -> Lwt_result.fail InvalidCharacter
        | Some entity_id ->
            let* () =
              match%lwt Ecs.Entity.ensure_exists entity_id with
              | Ok () -> Lwt_result.return ()
              | Error e -> Lwt_result.fail (DatabaseError (Base.Error.to_string_hum e))
            in
            let char_comp = Components.CharacterComponent.{ entity_id = character.id; user_id = character.user_id } in
            let* () = wrap_ok (Ecs.CharacterStorage.set entity_id char_comp) in

            (* Create / update ProgressionComponent *)
            let power_budget = Game_balance.power_budget_for_level character.proficiency_level in
            let prog_comp = Components.ProgressionComponent.{
              entity_id = character.id;
              proficiency_level = character.proficiency_level;
              current_xp = character.current_xp;
              saga_tier = character.saga_tier;
              current_ip = character.current_ip;
              power_budget;
            } in
            let* () = wrap_ok (Ecs.ProgressionStorage.set entity_id prog_comp) in

            let* pos_opt = wrap_val (Ecs.CharacterPositionStorage.get entity_id) in
            let* () = match pos_opt with
              | Some _ -> Lwt_result.return ()
              | None ->
                  let pos_comp = Components.CharacterPositionComponent.{ entity_id = character.id; area_id = "00000000-0000-0000-0000-000000000000" } in
                  wrap_ok (Ecs.CharacterPositionStorage.set entity_id pos_comp)
            in

            (* Stats will be recalculated by StatRecalculationSystem after LoadoutChanged *)
            State.set_active_character state ~user_id:character.user_id ~entity_id;

            (* Ensure the area entity is loaded into ECS so area systems can operate *)
            let area_id =
              match (Ecs.CharacterPositionStorage.get entity_id |> Lwt.map Option.return) with _ -> "00000000-0000-0000-0000-000000000000" in
            let* () = wrap_ok (State.enqueue ?trace_id state (Event.LoadAreaIntoECS { area_id })) in

            let* () = wrap_ok (State.enqueue ?trace_id state (Event.CharacterActivated { user_id = character.user_id; character_id = character.id })) in
            Lwt_result.return ()
end
module LoadCharacter = System.Make(LoadCharacterLogic)