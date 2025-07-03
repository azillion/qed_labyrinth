(* This file contains both character system and character communication system modules *)

module Character_list_system = struct

  let handle_character_list_requested state user_id =
    let open Lwt_result.Syntax in
    let* character_components = Ecs.CharacterStorage.all () |> Lwt_result.ok in
    match character_components with
    | [] ->
        (* No ECS characters – pull them from Tier-1 *)
        let* db_chars = Character.find_all_by_user ~user_id in
        let characters =
          Base.List.map db_chars ~f:(fun c -> Types.{ id = c.id; name = c.name })
        in
        Infra.Queue.push state.State.event_queue
          (Event.SendCharacterList { user_id; characters }) |> Lwt_result.ok
    | character_components ->
        (* Filter characters by user_id *)
        let user_characters = Base.List.filter character_components ~f:(fun (_, component) ->
          String.equal component.Components.CharacterComponent.user_id user_id
        ) in
        
        (* Get description and position components for each character *)
        let%lwt characters_with_details = Lwt_list.map_s (fun (entity_id, _char_component) ->
          let%lwt desc_opt = Ecs.DescriptionStorage.get entity_id in
          let%lwt pos_opt = Ecs.CharacterPositionStorage.get entity_id in
          
          match desc_opt with
          | Some desc -> 
              let _location_id = match pos_opt with
                | Some pos -> pos.Components.CharacterPositionComponent.area_id
                | None -> "00000000-0000-0000-0000-000000000000" (* Default starting area *)
              in
              
              let entity_id_str = Uuidm.to_string entity_id in
              let list_character : Types.list_character = {
                id = entity_id_str;
                name = desc.Components.DescriptionComponent.name
              } in
              Lwt.return (Some list_character)
          | None -> Lwt.return None
        ) user_characters in
        
        (* Filter out None values and convert to protocol format *)
        let characters = 
          Base.List.filter_map characters_with_details ~f:(fun char_opt -> char_opt)
        in
        
        (* Queue the event to send character list to the client *)
        let%lwt () = Infra.Queue.push state.State.event_queue (Event.SendCharacterList { user_id; characters }) in
        Lwt_result.return ()

  (* System implementation for ECS *)
  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 

module Character_list_communication_system = struct
  (* Handles sending character list to clients *)
  
  let handle_character_list state user_id characters =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        (* Send character list to the client *)
        client.Client.send (Protocol.CharacterList { characters })
    | None -> 
        (* User not connected, nothing to do *)
        Lwt.return_unit

  (* System implementation for ECS *)
  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Character_creation_system = struct
  let handle_create_character state user_id name _description _starting_area_id =
    let open Lwt_result.Syntax in
    (* Call the Character.create function from relational model *)
    let* character = Character.create ~user_id ~name in
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

module Character_creation_communication_system = struct
  (* Handles sending character creation responses to clients *)
  
  let handle_character_created state user_id character =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        client.Client.send (Protocol.CharacterCreated { character })
    | None -> Lwt.return_unit

  let handle_character_creation_failed state user_id error =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        client.Client.send (Protocol.CharacterCreationFailed { error })
    | None -> Lwt.return_unit

  (* System implementation for ECS *)
  let priority = 50

  let execute () =
    Lwt.return_unit
end

module Character_selection_system = struct
  let handle_character_selected state user_id character_id =
    (* Queue LoadCharacterIntoECS event *)
    let%lwt () = Infra.Queue.push state.State.event_queue (
      Event.LoadCharacterIntoECS { user_id; character_id }
    ) in
    Lwt_result.return ()

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Character_selection_communication_system = struct
  (* Handles sending character selection responses to clients *)
  
  let handle_character_selected state user_id character_sheet =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        begin
          try%lwt 
            let%lwt result = client.Client.send (Protocol.CharacterSelected { character_sheet }) in
            Lwt.return result
          with exn ->
            Stdio.eprintf "[ERROR] Exception sending CharacterSelected message: %s\n" (Printexc.to_string exn);
            Lwt.return_unit
        end
    | None -> 
        Stdio.eprintf "[ERROR] Client not found for user: %s when sending CharacterSelected\n" user_id;
        Lwt.return_unit

  let handle_character_selection_failed state user_id error =
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        begin
          try%lwt
            let%lwt result = client.Client.send (Protocol.CharacterSelectionFailed { error }) in
            Lwt.return result
          with exn ->
            Stdio.eprintf "[ERROR] Exception sending CharacterSelectionFailed message: %s\n" (Printexc.to_string exn);
            Lwt.return_unit
        end
    | None -> 
        Stdio.eprintf "[ERROR] Client not found for user: %s when sending CharacterSelectionFailed\n" user_id;
        Lwt.return_unit

  (* System implementation for ECS *)
  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end
