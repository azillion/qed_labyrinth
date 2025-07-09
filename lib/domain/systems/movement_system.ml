open Base
open Qed_error
open Exit
open Error_utils

module System = struct
  let find_character_by_user_id state user_id =
    match Base.Hashtbl.find state.State.active_characters user_id with
    | Some entity_id -> Lwt.return (Some entity_id)
    | None ->
        (* Fallback scan *)
        let%lwt characters = Ecs.CharacterStorage.all () in
        Lwt.return (List.find_map characters ~f:(fun (entity_id, comp) ->
          if String.equal comp.Components.CharacterComponent.user_id user_id then
            Some entity_id
          else
            None))

  let handle_move (state : State.t) user_id direction =
    let open Lwt_result.Syntax in
    
    let* char_entity_id =
      find_character_by_user_id state user_id |> Lwt.map (Result.of_option ~error:CharacterNotFound)
    in
    let* position_comp =
      Ecs.CharacterPositionStorage.get char_entity_id |> Lwt.map (Result.of_option ~error:(ServerError "Character has no position"))
    in
    let current_area_id = position_comp.area_id in

    (* DEBUG *)
    Stdio.printf"[MOVE] Current area for user %s is %s\n" user_id current_area_id;
    Stdio.Out_channel.flush Stdio.stdout;

    let* exit_opt = Exit.find_by_area_and_direction ~area_id:current_area_id ~direction in

    match exit_opt with
    | None ->
        let* () = Publisher.publish_system_message_to_user state user_id "You can't go that way." in
        Lwt_result.return ()
    | Some exit_record ->
        let new_area_id = exit_record.to_area_id in

        let* char_name =
          Communication_system.System.get_character_name char_entity_id |> Lwt.map (Result.of_option ~error:CharacterNotFound)
        in
        
        let direction_str = Components.ExitComponent.direction_to_string direction in
        let departure_msg_content = Printf.sprintf "%s has left, heading %s." char_name direction_str in
        let* departure_msg =
          Communication.create ~message_type:System ~sender_id:None ~content:departure_msg_content ~area_id:(Some current_area_id)
        in
        let* () = wrap_ok (Infra.Queue.push state.event_queue (Event.Announce { area_id = current_area_id; message = departure_msg })) in
        
        let new_pos_comp = { position_comp with area_id = new_area_id } in
        let* () = wrap_ok (Ecs.CharacterPositionStorage.set char_entity_id new_pos_comp) in

        let* () = wrap_ok (Infra.Queue.push state.event_queue
          (Event.PlayerMoved { user_id; old_area_id = current_area_id; new_area_id; direction })) in

        Lwt_result.return ()
end