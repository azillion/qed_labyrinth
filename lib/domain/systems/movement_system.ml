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
    
    (* Find the character entity *)
    let* char_entity_id =
      let%lwt eid_opt = find_character_by_user_id user_id in
      match eid_opt with
      | Some eid -> Lwt.return_ok eid
      | None -> Lwt.return_error CharacterNotFound
    in

    (* Get character's current position *)
    let* position_comp =
      let%lwt pos_opt = Ecs.CharacterPositionStorage.get char_entity_id in
      match pos_opt with
      | Some pos -> Lwt.return_ok pos
      | None -> Lwt.return_error (ServerError "Character has no position")
    in
    let current_area_id = position_comp.area_id in

    (* Find a valid exit in the given direction *)
    let* all_exits = Ecs.ExitStorage.all () |> Lwt_result.ok in
    let exit_opt =
      List.find all_exits ~f:(fun (_, exit_comp) ->
        String.equal exit_comp.from_area_id current_area_id &&
        phys_equal exit_comp.direction direction)
    in

    match exit_opt with
    | None ->
        (* No exit found, queue a failure event *)
        let%lwt () = Infra.Queue.push state.event_queue
          (Event.SendMovementFailed { user_id; reason = "You can't go that way." }) in
        Lwt.return_ok ()
    | Some (_, exit_comp) ->
        (* Exit found, update position *)
        let new_area_id = exit_comp.to_area_id in
        let new_pos_comp = { position_comp with area_id = new_area_id } in
        let* () = Ecs.CharacterPositionStorage.set char_entity_id new_pos_comp |> Lwt_result.ok in

        (* Queue PlayerMoved event for other systems to handle *)
        let%lwt () = Infra.Queue.push state.event_queue
          (Event.PlayerMoved { user_id; old_area_id = current_area_id; new_area_id }) in
        Lwt.return_ok ()
end