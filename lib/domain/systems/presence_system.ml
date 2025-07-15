open Base

module System = struct
  let get_character_name_by_user_id state user_id =
    let%lwt char_entity_opt = Movement_system.System.find_character_by_user_id state user_id in
    match char_entity_opt with
    | None -> Lwt.return_none
    | Some char_entity_id ->
        let char_id_str = Uuidm.to_string char_entity_id in
        let%lwt char_res = Character.find_by_id char_id_str in
        (match char_res with
        | Ok (Some char_record) -> Lwt.return (Some char_record.name)
        | Ok None -> Lwt.return_none
        | Error _ -> Lwt.return_none)

  let handle_player_moved (state : State.t) user_id _old_area_id new_area_id _direction =
    let open Lwt_result.Syntax in

    (* Area data now always available via relational storage; no ECS load needed. *)
    let* () = Error_utils.wrap_ok Lwt.return_unit in

    (* 1. Client movement is now handled by the API server via Redis events *)

    (* 2. Attempt to fetch the character's name for announcement purposes, but don't fail the move if we can't find it. *)
    let* char_name_opt = get_character_name_by_user_id state user_id |> Lwt.map Result.return in

    (* 3. Announce the arrival if we have the character's name. *)
    let* () =
      match char_name_opt with
      | None -> Lwt.return_ok ()  (* No name found – just skip the announcement. *)
      | Some char_name ->
          let arrival_msg_content = Printf.sprintf "%s has arrived." char_name in
          let* arrival_msg =
            Communication.create
              ~message_type:System
              ~sender_id:None
              ~content:arrival_msg_content
              ~area_id:(Some new_area_id)
          in
          Error_utils.wrap_ok (Infra.Queue.push state.event_queue (Event.Announce { area_id = new_area_id; message = arrival_msg }))
    in

    (* 4. Send the new area info and chat history to the moving player regardless. *)
    let* () = Error_utils.wrap_ok (Infra.Queue.push state.event_queue (Event.AreaQuery { user_id; area_id = new_area_id })) in
    Lwt.return_ok ()
end