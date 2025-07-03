open Base

module System = struct
  let handle_player_moved (state : State.t) user_id char_name old_area_id new_area_id direction =
    let open Lwt_result.Syntax in
    (* Announce departure to the old area *)
    let direction_str = Components.ExitComponent.direction_to_string direction in
    let departure_msg_content = Printf.sprintf "%s has left, heading %s." char_name direction_str in
    let departure_msg = {
      Types.sender_id = None;
      message_type = Types.System;
      content = departure_msg_content;
      timestamp = Unix.time ();
      area_id = Some old_area_id;
    } in
    let* () = Infra.Queue.push state.event_queue (Event.Announce { area_id = old_area_id; message = departure_msg }) |> Lwt_result.ok in

    (* Update Connection Manager *)
    (match Connection_manager.find_client_by_user_id state.connection_manager user_id with
    | Some client ->
        Connection_manager.move_client state.connection_manager
          ~client_id:client.Client.id
          ~new_room_id:new_area_id
    | None -> ());

    let arrival_msg_content = Printf.sprintf "%s has arrived." char_name in

    (* Create the arrival message *)
    let arrival_msg = {
      Types.sender_id = None;
      message_type = Types.System;
      content = arrival_msg_content;
      timestamp = Unix.time ();
      area_id = Some new_area_id;
    } in

    (* Announce arrival to the new area *)
    let* () = Infra.Queue.push state.event_queue (Event.Announce { area_id = new_area_id; message = arrival_msg }) |> Lwt_result.ok in
    
    (* Finally, query the new area for the moving player *)
    let* () = Infra.Queue.push state.event_queue (Event.AreaQuery { user_id; area_id = new_area_id }) |> Lwt_result.ok in
    Lwt.return_ok ()
end