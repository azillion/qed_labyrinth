open Base
open Qed_error
open Exit
open Error_utils
open Infra

module MoveLogic : System.S with type event = Event.move_payload = struct
  let name = "Move"
  type event = Event.move_payload
  let event_type = function Event.Move e -> Some e | _ -> None

  let find_character_by_user_id state user_id =
    match Base.Hashtbl.find state.State.active_characters user_id with
    | Some entity_id -> Lwt.return (Some entity_id)
    | None ->
        let%lwt characters = Ecs.CharacterStorage.all () in
        Lwt.return (List.find_map characters ~f:(fun (entity_id, (comp : Components.CharacterComponent.t)) ->
          let { Components.CharacterComponent.user_id = comp_user_id; _ } = comp in
          if String.equal comp_user_id user_id then
            Some entity_id
          else
            None))

  let execute state trace_id ({ user_id; direction } : event) =
    let open Lwt_result.Syntax in
    let* char_entity_id =
      find_character_by_user_id state user_id |> Lwt.map (Result.of_option ~error:CharacterNotFound)
    in
    let* position_comp =
      Ecs.CharacterPositionStorage.get char_entity_id |> Lwt.map (Result.of_option ~error:(ServerError "Character has no position"))
    in
    let current_area_id = position_comp.area_id in

    let* exit_opt = Exit.find_by_area_and_direction ~area_id:current_area_id ~direction in

    match exit_opt with
    | None ->
        let* () = Publisher.publish_system_message_to_user state ?trace_id user_id "You can't go that way." in
        Lwt_result.return ()
    | Some exit_record ->
        let new_area_id = exit_record.to_area_id in
        let char_id_str = Uuidm.to_string char_entity_id in

        let* char_name =
          (let%lwt name_res = Character.find_by_id char_id_str () in
           match name_res with
           | Ok (Some c) -> Lwt.return_ok c.name
           | _ -> Lwt.return_error CharacterNotFound)
        in
        
        let direction_str = Components.ExitComponent.direction_to_string direction in
        let departure_msg_content = Printf.sprintf "%s has left, heading %s." char_name direction_str in
        let* departure_msg =
          Communication.create ~message_type:System ~sender_id:None ~content:departure_msg_content ~area_id:(Some current_area_id)
        in
        let* () = wrap_ok (Queue.push state.event_queue (trace_id, Event.Announce { area_id = current_area_id; message = departure_msg })) in
        
        let new_pos_comp = { position_comp with area_id = new_area_id } in
        let* () = wrap_ok (Ecs.CharacterPositionStorage.set char_entity_id new_pos_comp) in

        let* () = wrap_ok (Queue.push state.event_queue (trace_id,
          (Event.PlayerMoved { user_id; old_area_id = current_area_id; new_area_id; direction }))) in

        Lwt_result.return ()
end
module Move = System.Make(MoveLogic)