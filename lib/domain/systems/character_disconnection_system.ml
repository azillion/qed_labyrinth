open Error_utils

module CharacterDisconnectionLogic : System.S with type event = Event.player_disconnected_payload = struct
  let name = "CharacterDisconnection"
  type event = Event.player_disconnected_payload
  let event_type = function Event.PlayerDisconnected e -> Some e | _ -> None

  let execute state trace_id (payload : event) =
    let user_id = payload.user_id in
    let open Lwt_result.Syntax in
    match State.get_active_character state user_id with
    | None ->
        (* Nothing to unload; just log and exit successfully *)
        let* () = wrap_ok (Infra.Monitoring.Log.debug "No active character for disconnected player" ~data:[("user_id", user_id)] ()) in
        Lwt_result.return ()
    | Some entity_id ->
        let character_id = Uuidm.to_string entity_id in
        let* () = wrap_ok (State.enqueue ?trace_id state (Event.UnloadCharacterFromECS { user_id; character_id })) in
        Lwt_result.return ()
end

module CharacterDisconnection = System.Make(CharacterDisconnectionLogic) 