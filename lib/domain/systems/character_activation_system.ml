open Error_utils

module CharacterActivatedLogic : System.S with type event = Event.character_activated_payload = struct
  let name = "CharacterActivated"
  type event = Event.character_activated_payload
  let event_type = function Event.CharacterActivated e -> Some e | _ -> None

  let execute state trace_id ({ user_id; character_id } : event) =
    let open Lwt_result.Syntax in
    (* Determine current area for query *)
    let* area_id =
      match Uuidm.of_string character_id with
      | None ->
          let* () = wrap_ok (Infra.Monitoring.Log.warn "Character ID is not a valid UUID; defaulting area_id" ~data:[("character_id", character_id)] ()) in
          Lwt_result.return "00000000-0000-0000-0000-000000000000"
      | Some ent_id ->
          let* pos_opt = wrap_val (Ecs.CharacterPositionStorage.get ent_id) in
          (match pos_opt with
          | Some p -> Lwt_result.return p.area_id
          | None ->
              let* () = wrap_ok (Infra.Monitoring.Log.warn "Character position missing; defaulting area_id" ~data:[("character_id", character_id)] ()) in
              Lwt_result.return "00000000-0000-0000-0000-000000000000")
    in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.AreaQuery { user_id; area_id })) in

    let* () = wrap_ok (State.enqueue ?trace_id state (Event.LoadoutChanged { character_id })) in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.RequestCharacterSheet { user_id; character_id })) in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.RequestInventory { user_id; character_id })) in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.RequestLoreCollection { user_id; character_id })) in
    Lwt_result.return ()
end

module CharacterActivated = System.Make(CharacterActivatedLogic) 