open Base
open Qed_error
open Error_utils

(* --- Say System --- *)
module SayLogic : System.S with type event = Event.say_payload = struct
  let name = "say"
  type event = Event.say_payload
  let event_type = function Event.Say e -> Some e | _ -> None

  let execute state trace_id ({ user_id; content } : event) =
    let open Lwt_result.Syntax in
    let* char_entity_id =
      (match State.get_active_character state user_id with
      | Some eid -> Lwt.return_ok eid
      | None -> Lwt.return_error CharacterNotFound)
    in
    let* char_pos = Ecs.CharacterPositionStorage.get char_entity_id |> Lwt.map (Result.of_option ~error:(ServerError "Character has no position")) in
    let area_id = char_pos.area_id in
    let sender_char_id_str = Some (Uuidm.to_string char_entity_id) in
    let* message = Communication.create ~message_type:Chat ~sender_id:sender_char_id_str ~content ~area_id:(Some area_id) in
    let* () = wrap_ok (State.enqueue ?trace_id state (Event.Announce { area_id; message })) in
    Lwt.return_ok ()
end
module Say = System.Make(SayLogic)

(* --- Announce System --- *)
module AnnounceLogic : System.S with type event = Event.announce_payload = struct
  let name = "announce"
  type event = Event.announce_payload
  let event_type = function Event.Announce e -> Some e | _ -> None

  let find_user_ids_in_area state area_id =
    let%lwt all_positions = Ecs.CharacterPositionStorage.all () in
    let characters_in_area = List.filter all_positions ~f:(fun (_, pos) -> String.equal pos.area_id area_id) |> List.map ~f:fst in
    let%lwt user_ids =
      Lwt_list.filter_map_s (fun char_id ->
        let%lwt char_comp_opt = Ecs.CharacterStorage.get char_id in
        match char_comp_opt with
        | None -> Lwt.return_none
        | Some char_comp ->
            (match State.get_active_character state char_comp.user_id with
            | Some active_eid when Uuidm.equal active_eid char_id -> Lwt.return (Some char_comp.user_id)
            | _ -> Lwt.return_none)
      ) characters_in_area
    in
    Lwt.return (List.dedup_and_sort user_ids ~compare:String.compare)

  let execute state trace_id ({ area_id; message } : event) =
    let open Lwt_result.Syntax in
    let* user_ids = find_user_ids_in_area state area_id |> Lwt.map (fun u -> Ok u) in
    let* () = wrap_ok (Lwt_list.iter_s (fun user_id -> State.enqueue ?trace_id state (Event.Tell { user_id; message })) user_ids) in
    Lwt_result.return ()
end
module Announce = System.Make(AnnounceLogic)

(* --- Tell System --- *)
module TellLogic : System.S with type event = Event.tell_payload = struct
  let name = "tell"
  type event = Event.tell_payload
  let event_type = function Event.Tell e -> Some e | _ -> None

  let get_sender_name sender_id =
    match sender_id with
    | None -> Lwt.return "System"
    | Some id_str ->
      match Uuidm.of_string id_str with
      | Some _char_entity_id ->
          let%lwt name_opt = (let%lwt res = Character.find_by_id id_str in Lwt.return (Result.ok res |> Option.bind ~f:Fn.id |> Option.map ~f:(fun c -> c.name))) in
          Lwt.return (Option.value name_opt ~default:"Unknown")
      | None -> Lwt.return "Unknown"

  let execute state trace_id ({ user_id; message } : event) =
    let open Lwt_result.Syntax in
    let message_type_str = match message.Communication.message_type with
      | Communication.Chat -> "Chat" | Communication.System -> "System" | _ -> "Chat"
    in
    let* sender_name = get_sender_name message.sender_id |> Lwt.map (fun n -> Ok n) in
    let chat_message = Schemas_generated.Output.{ sender_name; content = message.content; message_type = message_type_str; } in
    let output_event = Schemas_generated.Output.{ target_user_ids = [user_id]; payload = Chat_message chat_message; trace_id = "" } in
    let* () = Publisher.publish_event state ?trace_id output_event in
    Lwt_result.return ()
end
module Tell = System.Make(TellLogic)

(* --- Request Chat History System --- *)
module RequestChatHistoryLogic : System.S with type event = Event.request_chat_history_payload = struct
    let name = "request-chat-history"
    type event = Event.request_chat_history_payload
    let event_type = function Event.RequestChatHistory e -> Some e | _ -> None

    let execute state trace_id ({ user_id; area_id } : event) =
        let open Lwt_result.Syntax in
        let* messages = Communication.find_by_area_id area_id in
        let chat_messages = List.map messages ~f:Types.chat_message_of_model in
        let* () = wrap_ok (State.enqueue ?trace_id state (Event.SendChatHistory { user_id; messages = chat_messages })) in
        Lwt.return_ok ()
end
module RequestChatHistory = System.Make(RequestChatHistoryLogic)

(* --- Send Chat History System --- *)
module SendChatHistoryLogic : System.S with type event = Event.send_chat_history_payload = struct
    let name = "send-chat-history"
    type event = Event.send_chat_history_payload
    let event_type = function Event.SendChatHistory e -> Some e | _ -> None

    let execute state trace_id ({ user_id; messages } : event) =
        let open Lwt_result.Syntax in

        (* 1. Collect unique sender IDs *)
        let sender_ids =
            List.filter_map messages ~f:(fun msg -> msg.sender_id)
            |> List.dedup_and_sort ~compare:String.compare
        in

        (* 2. Bulk fetch character names *)
        let* char_name_map =
            if List.is_empty sender_ids then Lwt.return_ok (Map.empty (module String))
            else
              match%lwt Character.find_many_by_ids sender_ids with
              | Ok chars ->
                  let map =
                      List.map chars ~f:(fun c -> (c.id, c.name))
                      |> Map.of_alist_exn (module String)
                  in
                  Lwt.return_ok map
              | Error e -> Lwt.return_error e
        in

        (* 3. Convert messages to protobuf *)
        let pb_messages =
            List.map messages ~f:(fun (msg : Types.chat_message) ->
                let sender_name =
                    match msg.sender_id with
                    | Some id -> Map.find char_name_map id |> Option.value ~default:"Unknown"
                    | None -> "System"
                in
                let message_type_str = match msg.message_type with
                  | Communication.Chat -> "Chat" | Communication.System -> "System" | _ -> "Chat"
                in
                Schemas_generated.Output.{ sender_name; content = msg.content; message_type = message_type_str }
            )
        in

        let chat_history_msg : Schemas_generated.Output.chat_history = { messages = pb_messages } in
        let output_event : Schemas_generated.Output.output_event = { target_user_ids = [user_id]; payload = Chat_history chat_history_msg; trace_id = "" } in
        let* () = Publisher.publish_event state ?trace_id output_event in
        Lwt_result.return ()
end
module SendChatHistory = System.Make(SendChatHistoryLogic)