open Base
open Qed_error

module System = struct
  let find_character_by_user_id state user_id =
    match Base.Hashtbl.find state.State.active_characters user_id with
    | Some entity_id -> Lwt.return (Some entity_id)
    | None ->
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

  let find_user_ids_in_area state area_id =
    let%lwt all_positions = Ecs.CharacterPositionStorage.all () in
    (* Characters physically present in the area *)
    let characters_in_area =
      List.filter all_positions ~f:(fun (_, pos) -> String.equal pos.area_id area_id)
      |> List.map ~f:fst
    in

    (* Map to user_ids only if this entity is the user's active character *)
    let%lwt user_ids =
      Lwt_list.filter_map_s (fun char_id ->
        let%lwt char_comp_opt = Ecs.CharacterStorage.get char_id in
        match char_comp_opt with
        | None -> Lwt.return_none
        | Some char_comp ->
            (match State.get_active_character state char_comp.user_id with
            | Some active_eid when Uuidm.equal active_eid char_id ->
                Lwt.return (Some char_comp.user_id)
            | _ -> Lwt.return_none)
      ) characters_in_area
    in
    (* Dedupe user ids to avoid duplicate messages when somehow duplicates slip through *)
    let unique_user_ids = Base.List.dedup_and_sort user_ids ~compare:String.compare in
    Lwt.return unique_user_ids

  let handle_say state user_id content =
    let open Lwt_result.Syntax in
    let* char_entity_id = find_character_by_user_id state user_id |> Lwt.map (Result.of_option ~error:CharacterNotFound) in
    let* char_pos = get_character_position char_entity_id |> Lwt.map (Result.of_option ~error:(ServerError "Character has no position")) in
    let area_id = char_pos.area_id in

    (* Create and persist the chat message *)
    let* message =
      Communication.create ~message_type:Chat ~sender_id:(Some user_id) ~content ~area_id:(Some area_id)
    in

    (* Announce the persisted message *)
    let* () = Infra.Queue.push state.State.event_queue (Event.Announce { area_id; message }) |> Lwt_result.ok in
    Lwt.return_ok ()

  let handle_announce state area_id message =
    let open Lwt.Syntax in
    let* user_ids = find_user_ids_in_area state area_id in
    let* () =
      Lwt_list.iter_s (fun user_id ->
        Infra.Queue.push state.State.event_queue (Event.Tell { user_id; message })
      ) user_ids
    in
    Lwt_result.return ()

  let handle_tell state user_id message =
    (match Connection_manager.find_client_by_user_id state.State.connection_manager user_id with
    | Some client ->
        let chat_message = Types.chat_message_of_model message in
        client.send (Protocol.ChatMessage { message = chat_message })
    | None -> Lwt.return_unit)
    |> Lwt_result.ok
end

module Chat_history_system = struct
  let handle_request_chat_history (state: State.t) user_id area_id =
    let open Lwt_result.Syntax in
    let* messages = Communication.find_by_area_id area_id in
    let chat_messages = List.map messages ~f:Types.chat_message_of_model in

    let%lwt () = Infra.Queue.push state.event_queue (Event.SendChatHistory { user_id; messages = chat_messages }) in
    Lwt.return_ok ()

  let handle_send_chat_history (state: State.t) user_id messages =
    (match Connection_manager.find_client_by_user_id state.connection_manager user_id with
    | Some client ->
        client.send (Protocol.ChatHistory { messages })
    | None -> Lwt.return_unit)
    |> Lwt_result.ok
end