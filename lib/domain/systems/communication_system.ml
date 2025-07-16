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
    let char_id_str = Uuidm.to_string entity_id in
    let%lwt char_res = Character.find_by_id char_id_str in
    match char_res with
    | Ok (Some char_record) -> Lwt.return (Some char_record.name)
    | _ -> Lwt.return_none

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

  let get_sender_name state sender_id =
    match sender_id with
    | None -> Lwt.return "System"
    | Some id_str -> (
        match Uuidm.of_string id_str with
        | Some char_entity_id ->
            (* We were given a character entity id – look up its name directly. *)
            let%lwt name_opt = get_character_name char_entity_id in
            Lwt.return (Option.value name_opt ~default:"Unknown")
        | None ->
            (* Fallback for legacy records where we stored the user_id instead of
               the character id. Retain the old behaviour for backward
               compatibility. *)
            let%lwt char_entity_id_opt = find_character_by_user_id state id_str in
            (match char_entity_id_opt with
            | None -> Lwt.return "Unknown"
            | Some char_entity_id ->
                let%lwt name_opt = get_character_name char_entity_id in
                Lwt.return (Option.value name_opt ~default:"Unknown")))

  let handle_say state user_id content =
    let open Lwt_result.Syntax in
    let* char_entity_id = find_character_by_user_id state user_id |> Lwt.map (Result.of_option ~error:CharacterNotFound) in
    let* char_pos = get_character_position char_entity_id |> Lwt.map (Result.of_option ~error:(ServerError "Character has no position")) in
    let area_id = char_pos.area_id in

    (* Create and persist the chat message.
       We now store the character entity id instead of the user_id so that the
       sender name remains stable even if the user later switches active
       characters. *)
    let sender_char_id_str = Some (Uuidm.to_string char_entity_id) in
    let* message =
      Communication.create ~message_type:Chat ~sender_id:sender_char_id_str ~content ~area_id:(Some area_id)
    in

    (* Announce the persisted message *)
    let* () = Error_utils.wrap_ok (State.enqueue state (Event.Announce { area_id; message })) in
    Lwt.return_ok ()

  let handle_announce state area_id message =
    let open Lwt_result.Syntax in
    let* user_ids = find_user_ids_in_area state area_id |> Lwt.map (fun u -> Ok u) in
    let* () = Error_utils.wrap_ok (
      Lwt_list.iter_s (fun user_id ->
        State.enqueue state (Event.Tell { user_id; message })
      ) user_ids)
    in
    Lwt_result.return ()

  let handle_tell state user_id message =
    let open Lwt_result.Syntax in
    let message_type_str = match message.Communication.message_type with
      | Communication.Chat -> "Chat"
      | Communication.System -> "System"
      | Communication.Emote -> "Emote"
      | Communication.CommandSuccess -> "CommandSuccess"
      | Communication.CommandFailed -> "CommandFailed"
    in
    let* sender_name = get_sender_name state message.sender_id |> Lwt.map (fun n -> Ok n) in
    let chat_message = Schemas_generated.Output.{
      sender_name;
      content = message.content;
      message_type = message_type_str;
    } in
    let output_event = Schemas_generated.Output.{
      target_user_ids = [user_id];
      payload = Chat_message chat_message;
      trace_id = "";
    } in
    let* () = Publisher.publish_event state output_event in
    Lwt_result.return ()
end

module Chat_history_system = struct
  let handle_request_chat_history (state: State.t) user_id area_id =
    let open Lwt_result.Syntax in
    let* messages = Communication.find_by_area_id area_id in
    let chat_messages = List.map messages ~f:Types.chat_message_of_model in

    let%lwt () = State.enqueue state (Event.SendChatHistory { user_id; messages = chat_messages }) in
    Lwt.return_ok ()

  (* Publish the requested chat history to the user as a single payload *)
  let handle_send_chat_history (state : State.t) (user_id : string) (messages : Types.chat_message list) =
    let open Lwt_result.Syntax in

    (* Transform each domain chat_message into its protobuf equivalent *)
    let%lwt pb_messages = Lwt_list.map_s (fun (msg : Types.chat_message) ->
      let message_type_str = match msg.message_type with
        | Communication.Chat -> "Chat"
        | Communication.System -> "System"
        | Communication.Emote -> "Emote"
        | Communication.CommandSuccess -> "CommandSuccess"
        | Communication.CommandFailed -> "CommandFailed"
      in
      let%lwt sender_name = System.get_sender_name state msg.sender_id in
      Lwt.return Schemas_generated.Output.{
        sender_name;
        content = msg.content;
        message_type = message_type_str;
      }
    ) messages in

    (* Bundle into ChatHistory message *)
    let chat_history_msg : Schemas_generated.Output.chat_history = {
      messages = pb_messages;
    } in

    let output_event : Schemas_generated.Output.output_event = {
      target_user_ids = [user_id];
      payload = Chat_history chat_history_msg;
      trace_id = "";
    } in

    let* () = Publisher.publish_event state output_event in
    Lwt_result.return ()
end