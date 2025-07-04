open Base

module System = struct
  let get_character_name_by_user_id state user_id =
    let%lwt char_entity_opt = Movement_system.System.find_character_by_user_id state user_id in
    match char_entity_opt with
    | None -> Lwt.return_none
    | Some char_entity_id ->
        let%lwt desc_opt = Ecs.DescriptionStorage.get char_entity_id in
        Lwt.return (Option.map desc_opt ~f:(fun d -> d.name))

  let handle_player_moved (state : State.t) user_id _old_area_id new_area_id _direction =
    let open Lwt_result.Syntax in

    (* 1. Always move the client to the new room, even if we cannot resolve the character's name *)
    (match Connection_manager.find_client_by_user_id state.connection_manager user_id with
    | Some client ->
        Connection_manager.move_client state.connection_manager
          ~client_id:client.Client.id
          ~new_room_id:new_area_id
    | None -> ());

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
          Infra.Queue.push state.event_queue (Event.Announce { area_id = new_area_id; message = arrival_msg })
          |> Lwt_result.ok
    in

    (* 4. Send the new area info and chat history to the moving player regardless. *)
    let* () = Infra.Queue.push state.event_queue (Event.AreaQuery { user_id; area_id = new_area_id }) |> Lwt_result.ok in
    Lwt.return_ok ()
end