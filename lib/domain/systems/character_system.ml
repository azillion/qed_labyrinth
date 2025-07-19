open Base
open Error_utils

(* --- Character List System --- *)
module CharacterListLogic : System.S with type event = Event.character_list_requested_payload = struct
  let name = "CharacterListRequested"
  type event = Event.character_list_requested_payload
  let event_type = function Event.CharacterListRequested e -> Some e | _ -> None

  let execute state trace_id payload =
    let user_id = (payload : event).user_id in
    let open Lwt.Syntax in
    let* () = Infra.Monitoring.Log.debug "Executing character list system" ~data:[("trace_id", Option.value trace_id ~default:"N/A")] () in
    let%lwt db_chars_result = Character.find_all_by_user ~user_id in
    let* db_chars = match db_chars_result with
      | Ok chars -> Lwt.return chars
      | Error e -> Lwt.fail (Failure (Qed_error.to_string e))
    in
    let pb_characters =
      List.map db_chars ~f:(fun c ->
        (Schemas_generated.Output.{ id = c.id; name = c.name }
          : Schemas_generated.Output.list_character))
    in
    let character_list_msg : Schemas_generated.Output.character_list = { characters = pb_characters } in
    let output_event : Schemas_generated.Output.output_event = {
      target_user_ids = [user_id];
      payload = Character_list character_list_msg;
      trace_id = Option.value trace_id ~default:""
    } in
    let%lwt publish_result = Publisher.publish_event state ?trace_id output_event in
    let* () = match publish_result with
      | Ok () -> Lwt.return ()
      | Error e -> Lwt.fail (Failure (Qed_error.to_string e))
    in
    Lwt.return_ok ()
end
module CharacterList = System.Make(CharacterListLogic)


(* --- Character Creation System --- *)
module CharacterCreateLogic : System.S with type event = Event.create_character_payload = struct
  let name = "CreateCharacter"
  type event = Event.create_character_payload
  let event_type = function Event.CreateCharacter e -> Some e | _ -> None

  let execute state trace_id payload =
    let user_id = (payload : event).user_id in
    let name = payload.name in
    let might = payload.might in
    let finesse = payload.finesse in
    let wits = payload.wits in
    let grit = payload.grit in
    let presence = payload.presence in
    let open Lwt_result.Syntax in
    let* character = Character.create ~user_id ~name ~might ~finesse ~wits ~grit ~presence in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.CharacterCreated { user_id; character_id = character.id })) in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.CharacterSelected { user_id; character_id = character.id })) in
    Lwt_result.return ()
end
module CharacterCreate = System.Make(CharacterCreateLogic)


(* --- Character Selection System --- *)
module CharacterSelectLogic : System.S with type event = Event.character_selected_payload = struct
  let name = "CharacterSelected"
  type event = Event.character_selected_payload
  let event_type = function Event.CharacterSelected e -> Some e | _ -> None

  let execute state trace_id payload =
    let user_id = (payload : event).user_id in
    let character_id = payload.character_id in
    let open Lwt_result.Syntax in
    let* () =
      match State.get_active_character state user_id with
      | Some old_entity ->
          let old_char_id = Uuidm.to_string old_entity in
          wrap_ok (State.enqueue ?trace_id state (Event.UnloadCharacterFromECS { user_id; character_id = old_char_id }))
      | None -> Lwt_result.return ()
    in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.LoadCharacterIntoECS { user_id; character_id })) in
    Lwt_result.return ()
end
module CharacterSelect = System.Make(CharacterSelectLogic)

