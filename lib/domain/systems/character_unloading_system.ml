open Qed_error

let handle_unload_character (state : State.t) user_id character_id =
  match Uuidm.of_string character_id with
  | None -> Lwt_result.fail InvalidCharacter
  | Some entity_id ->
      (* Keep CharacterStorage so character still appears in selection list *)
      let%lwt () = Ecs.CharacterPositionStorage.remove entity_id in
      (* Clear active mapping *)
      State.unset_active_character state ~user_id;
      Lwt_result.return () 