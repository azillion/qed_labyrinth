open Base
open Qed_error

module System = struct
  let find_character_by_user_id user_id =
    let%lwt characters = Ecs.CharacterStorage.all () in
    Lwt.return (List.find_map characters ~f:(fun (entity_id, comp) ->
      if String.equal comp.Components.CharacterComponent.user_id user_id then
        Some entity_id
      else
        None))

  let handle_move (state : State.t) user_id direction =
    let open Lwt_result.Syntax in
    
    let* char_entity_id =
      find_character_by_user_id user_id |> Lwt.map (Result.of_option ~error:CharacterNotFound)
    in
    let* position_comp =
      Ecs.CharacterPositionStorage.get char_entity_id |> Lwt.map (Result.of_option ~error:(ServerError "Character has no position"))
    in
    let current_area_id = position_comp.area_id in

    (* DEBUG *)
    Stdio.printf"[MOVE] Current area for user %s is %s\n" user_id current_area_id;
    Stdio.Out_channel.flush Stdio.stdout;

    let* all_exits = Ecs.ExitStorage.all () |> Lwt_result.ok in
    let exit_opt =
      List.find all_exits ~f:(fun (_, exit_comp) ->
        String.equal exit_comp.from_area_id current_area_id &&
         String.equal (Components.ExitComponent.direction_to_string exit_comp.direction)
                     (Components.ExitComponent.direction_to_string direction))
    in

    (* DEBUG *)
    (match exit_opt with
    | None -> Stdio.printf "[MOVE] No exit found from %s going %s\n" current_area_id (Components.ExitComponent.direction_to_string direction)
    | Some (_, exit_comp) -> Stdio.printf "[MOVE] Exit found: to_area=%s\n" exit_comp.Components.ExitComponent.to_area_id);
    Stdio.Out_channel.flush Stdio.stdout;

    match exit_opt with
    | None ->
        let* () = Infra.Queue.push state.event_queue
          (Event.SendMovementFailed { user_id; reason = "You can't go that way." }) |> Lwt_result.ok in
        Lwt.return_ok ()
    | Some (_, exit_comp) ->
        let new_area_id = exit_comp.to_area_id in

        (* DEBUG *)
        Stdio.printf "[MOVE] Moving user %s from %s to %s\n" user_id current_area_id new_area_id;
        Stdio.Out_channel.flush Stdio.stdout;

        let* char_name =
          Communication_system.System.get_character_name char_entity_id |> Lwt.map (Result.of_option ~error:CharacterNotFound)
        in
        
        (* Now, update the character's position *)
        let new_pos_comp = { position_comp with area_id = new_area_id } in
        let* () = Ecs.CharacterPositionStorage.set char_entity_id new_pos_comp |> Lwt_result.ok in

        (* Queue PlayerMoved event for arrival announcements and other consequences *)
        let* () = Infra.Queue.push state.event_queue
          (Event.PlayerMoved { user_id; char_name; old_area_id = current_area_id; new_area_id; direction }) |> Lwt_result.ok in

        (* DEBUG *)
        Stdio.printf "[MOVE] Queued PlayerMoved event for user %s\n" user_id;
        Stdio.Out_channel.flush Stdio.stdout;

        Lwt.return_ok ()
end