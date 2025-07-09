(* This file contains both character system and character communication system modules *)

module Character_list_system = struct

  let handle_character_list_requested state user_id =
    let open Lwt_result.Syntax in
    (* 1. Fetch all character blueprints for the user from the relational DB. *)
    let* db_chars = Character.find_all_by_user ~user_id in

    (* 2. Convert the relational records to the protobuf format. *)
    let pb_characters =
      Base.List.map db_chars ~f:(fun c ->
        (Schemas_generated.Output.{ id = c.id; name = c.name }
          : Schemas_generated.Output.list_character))
    in
    let character_list_msg : Schemas_generated.Output.character_list = { characters = pb_characters } in
    
    (* 3. Create the final output event payload. *)
    let output_event : Schemas_generated.Output.output_event = {
      target_user_ids = [user_id];
      payload = Character_list character_list_msg;
    } in

    (* 4. Publish the event to the user. *)
    let* () = Publisher.publish_event state output_event |> Lwt.map (fun () -> Ok ()) in
    Lwt_result.return ()

  (* System implementation for ECS *)
  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 

module Character_creation_system = struct
  let handle_create_character state user_id name _description _starting_area_id might finesse wits grit presence =
    let open Lwt_result.Syntax in
    (* Call the Character.create function from relational model *)
    let* character = Character.create ~user_id ~name ~might ~finesse ~wits ~grit ~presence in
    (* Log creation for observability *)
    Stdio.printf "[CREATE_CHARACTER] user=%s character_id=%s name=%s\n" user_id character.id name;
    (* Queue CharacterCreated event on success *)
    let%lwt () = Infra.Queue.push state.State.event_queue (
      Event.CharacterCreated { user_id; character_id = character.id }
    ) in
    Lwt_result.return ()

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 

module Character_selection_system = struct
  let handle_character_selected state user_id character_id =
    let%lwt () =
      match State.get_active_character state user_id with
      | Some old_entity ->
          let old_char_id = Uuidm.to_string old_entity in
          Infra.Queue.push state.event_queue (
            Event.UnloadCharacterFromECS { user_id; character_id = old_char_id }
          )
      | None -> Lwt.return_unit
    in
    (* Queue LoadCharacterIntoECS event *)
    let%lwt () = Infra.Queue.push state.event_queue (
      Event.LoadCharacterIntoECS { user_id; character_id }
    ) in
    Lwt_result.return ()

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

