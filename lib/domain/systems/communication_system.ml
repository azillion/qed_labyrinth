open Base
open Qed_error
open Ecs

module System = struct
  let find_character_by_user_id user_id =
    let%lwt characters = Ecs.CharacterStorage.all () in
    Lwt.return (List.find_map characters ~f:(fun (entity_id, comp) ->
      if String.equal comp.Components.CharacterComponent.user_id user_id then
        Some entity_id
      else
        None))

  let get_character_name entity_id =
    let%lwt desc_opt = Ecs.DescriptionStorage.get entity_id in
    Lwt.return (Option.map desc_opt ~f:(fun d -> d.name))

  let get_character_position entity_id =
    Ecs.CharacterPositionStorage.get entity_id

  let find_user_ids_in_area area_id =
    let%lwt all_positions = Ecs.CharacterPositionStorage.all () in
    let characters_in_area =
      List.filter all_positions ~f:(fun (_, pos) -> String.equal pos.area_id area_id)
      |> List.map ~f:fst
    in
    let%lwt user_ids =
      Lwt_list.map_s (fun char_id ->
        let%lwt char_comp_opt = Ecs.CharacterStorage.get char_id in
        Lwt.return (Option.map char_comp_opt ~f:(fun c -> c.user_id))
      ) characters_in_area
    in
    Lwt.return (List.filter_opt user_ids)

  let handle_say (state : State.t) user_id content =
    let open Lwt_result.Syntax in
    let* char_entity_id = find_character_by_user_id user_id |> Lwt.map (Result.of_option ~error:CharacterNotFound) in
    let* char_name = get_character_name char_entity_id |> Lwt.map (Result.of_option ~error:CharacterNotFound) in
    let* char_pos = get_character_position char_entity_id |> Lwt.map (Result.of_option ~error:(ServerError "Character has no position")) in
    let area_id = char_pos.area_id in

    let message_content = Printf.sprintf "%s says, \"%s\"" char_name content in
    let message = {
      Types.sender_id = Some user_id;
      message_type = Chat;
      content = message_content;
      timestamp = Unix.time ();
      area_id = Some area_id;
    } in

    let* () = Infra.Queue.push state.event_queue (Event.Announce { area_id; message }) |> Lwt_result.ok in
    Lwt.return_ok ()

  let handle_announce (state : State.t) area_id (message : Types.chat_message) =
    let open Lwt_result.Syntax in
    let chat_msg : Types.chat_message = message in
    (* Persist *)
    let* eid = Entity.create () |> Lwt.map (Result.map_error ~f:(fun _ -> Qed_error.DatabaseError "Failed to create entity")) in
    let comp = Components.CommunicationComponent.{
      entity_id   = Uuidm.to_string eid;
      area_id     = chat_msg.area_id;
      sender_id   = chat_msg.sender_id;
      message_type= chat_msg.message_type;
      content     = chat_msg.content;
      timestamp   = chat_msg.timestamp;
    } in
    let* () = CommunicationStorage.set eid comp |> Lwt_result.ok in

    (* Fan-out *)
    let* user_ids = find_user_ids_in_area area_id |> Lwt_result.ok in
    let* () =
      Lwt_list.iter_s (fun uid ->
        Infra.Queue.push state.event_queue (Event.Tell { user_id = uid; message = chat_msg })
      ) user_ids |> Lwt_result.ok
    in
    Lwt_result.return ()

  let handle_tell (state : State.t) user_id message =
    let open Lwt_result.Syntax in
    let* () =
      match Connection_manager.find_client_by_user_id state.connection_manager user_id with
      | Some client ->
          Stdio.printf "[TELL] Sending message to user %s: %s\n" user_id message.Types.content;
          Stdio.Out_channel.flush Stdio.stdout;
          client.Client.send (Protocol.ChatMessage { message }) |> Lwt_result.ok
      | None -> Lwt_result.return ()
    in
    Lwt_result.return ()
end

module Chat_history_system = struct
  let handle_request_chat_history (state : State.t) user_id area_id =
    let open Lwt_result.Syntax in
    (* Retrieve all stored communications *)
    let* all = Ecs.CommunicationStorage.all () |> Lwt_result.ok in
    let history =
      List.filter_map all ~f:(fun (_, comp) ->
        match comp.Components.CommunicationComponent.area_id with
        | Some id when String.equal id area_id ->
            let msg : Types.chat_message = {
              sender_id    = comp.sender_id;
              message_type = comp.message_type;
              content      = comp.content;
              timestamp    = comp.timestamp;
              area_id      = comp.area_id;
            } in
            Some msg
        | _ -> None)
      |> List.sort ~compare:(fun a b -> Float.compare a.timestamp b.timestamp)
    in
    let%lwt () = Infra.Queue.push state.event_queue (Event.SendChatHistory { user_id; messages = history }) in
    Lwt.return_ok ()

  let handle_send_chat_history (state : State.t) user_id messages =
    match Connection_manager.find_client_by_user_id state.connection_manager user_id with
    | Some client -> client.send (Protocol.ChatHistory { messages })
    | None -> Lwt.return_unit
end