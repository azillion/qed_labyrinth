(* This file contains both character system and character communication system modules *)

module Character_list_system = struct

  let handle_character_list_requested (state : State.t) user_id =
    let open Lwt_result.Syntax in
    let* character_components = Ecs.CharacterStorage.all () |> Lwt_result.ok in
    match character_components with
    | [] ->
        (* No characters found, queue an empty list event *)
        let* () = Infra.Queue.push state.event_queue (Event.SendCharacterList { user_id; characters = [] }) |> Lwt_result.ok in
        Lwt_result.return ()
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
        let%lwt () = Infra.Queue.push state.event_queue (Event.SendCharacterList { user_id; characters }) in
        Lwt_result.return ()

  (* System implementation for ECS *)
  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 

module Character_list_communication_system = struct
  (* Handles sending character list to clients *)
  
  let handle_character_list (state : State.t) user_id characters =
    let client_opt = Connection_manager.find_client_by_user_id state.connection_manager user_id in
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
  let handle_create_character (state : State.t) user_id name description starting_area_id =
    let open Lwt_result.Syntax in
    (* Create a new entity *)
    let* entity_id = Ecs.Entity.create () |> Lwt.map (Result.map_error (fun _ -> Qed_error.DatabaseError "Failed to create entity")) in
    let entity_id_str = Uuidm.to_string entity_id in
    
    (* Add CharacterComponent *)
    let character_comp = Components.CharacterComponent.{ 
      entity_id = entity_id_str; 
      user_id 
    } in
    let%lwt () = Ecs.CharacterStorage.set entity_id character_comp in
    
    (* Add DescriptionComponent *)
    let desc_comp = Components.DescriptionComponent.{ 
      entity_id = entity_id_str; 
      name; 
      description = Some description 
    } in
    let%lwt () = Ecs.DescriptionStorage.set entity_id desc_comp in
    
    (* Add CharacterPositionComponent *)
    let pos_comp = Components.CharacterPositionComponent.{ 
      entity_id = entity_id_str;
      area_id = starting_area_id 
    } in
    let%lwt () = Ecs.CharacterPositionStorage.set entity_id pos_comp in
    
    (* Find the client to update state *)
    let client_opt = Connection_manager.find_client_by_user_id state.connection_manager user_id in
    match client_opt with
    | Some client ->
        (* Update client state *)
        Client.set_character client entity_id_str;
        Connection_manager.add_to_room state.connection_manager 
          ~client_id:client.Client.id 
          ~room_id:starting_area_id;
        
        (* Queue events to inform client *)
        let list_character : Types.list_character = { id = entity_id_str; name } in
        let character_full : Types.character = {
          id = entity_id_str;
          name;
          location_id = starting_area_id;
          health = 100;
          max_health = 100;
          mana = 100;
          max_mana = 100;
          level = 1;
          experience = 0;
        } in
        (* Send both CharacterCreated (list form) and CharacterSelected (full) so UI can proceed *)
        let* () = Infra.Queue.push state.event_queue (Event.SendCharacterCreated { user_id; character = list_character }) |> Lwt_result.ok in
        let* () = Infra.Queue.push state.event_queue (Event.SendCharacterSelected { user_id; character = character_full }) |> Lwt_result.ok in
        (* Send initial area info using AreaQuery event *)
        let%lwt () = Infra.Queue.push state.event_queue (
          Event.AreaQuery { user_id; area_id = starting_area_id }
        ) in
        Lwt_result.return ()
    | None -> Lwt_result.return ()

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 

module Character_creation_communication_system = struct
  (* Handles sending character creation responses to clients *)
  
  let handle_character_created (state : State.t) user_id character =
    let client_opt = Connection_manager.find_client_by_user_id state.connection_manager user_id in
    match client_opt with
    | Some client ->
        client.Client.send (Protocol.CharacterCreated { character })
    | None -> Lwt.return_unit

  let handle_character_creation_failed (state : State.t) user_id error =
    let client_opt = Connection_manager.find_client_by_user_id state.connection_manager user_id in
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
  let handle_character_selected (state : State.t) user_id character_id =
    (* Check if character exists and belongs to the user *)
    match Uuidm.of_string character_id with
    | None ->
        Lwt_result.fail (Qed_error.InvalidCharacter)
    | Some entity_id ->
        (* Get character component to verify ownership *)
        let%lwt char_comp_opt = Ecs.CharacterStorage.get entity_id in
        match char_comp_opt with
        | None ->
            (* Character not found *)
            Lwt_result.fail (Qed_error.CharacterNotFound)
        | Some char_comp ->
            if not (String.equal char_comp.Components.CharacterComponent.user_id user_id) then
              (* Character doesn't belong to this user *)
              Lwt_result.fail (Qed_error.InvalidCharacter)
            else begin
              (* Character is valid and belongs to the user *)
              (* Get description and position components *)
              let%lwt desc_opt = Ecs.DescriptionStorage.get entity_id in
              let%lwt pos_opt = Ecs.CharacterPositionStorage.get entity_id in
              
              (* Find current location *)
              let location_id = match pos_opt with
                | Some pos -> pos.Components.CharacterPositionComponent.area_id
                | None -> "00000000-0000-0000-0000-000000000000" (* Default starting area *)
              in
              
              (* Get the name from description *)
              match desc_opt with
              | None ->
                  (* Missing description component *)
                  Lwt_result.fail (Qed_error.DatabaseError "Character data is incomplete")
              | Some desc ->
                  (* Build character model *)
                  let character : Types.character = {
                    id = character_id;
                    name = desc.Components.DescriptionComponent.name;
                    location_id;
                    health = 100; (* Default values *)
                    max_health = 100;
                    mana = 100;
                    max_mana = 100;
                    level = 1;
                    experience = 0;
                  } in
                  
                  (* Find the client *)
                  let client_opt = Connection_manager.find_client_by_user_id state.connection_manager user_id in
                  match client_opt with
                  | Some client ->
                      (* Update client state *)
                      Client.set_character client character_id;
                      
                      (* Add to character's current room *)
                      Connection_manager.add_to_room state.connection_manager
                        ~client_id:client.Client.id
                        ~room_id:location_id;
                      
                      (* Queue event to send character data to client *)
                      let%lwt () = Infra.Queue.push state.event_queue (
                        Event.SendCharacterSelected { user_id; character }
                      ) in
                      
                      (* Send area info using AreaQuery event *)
                      let%lwt () = Infra.Queue.push state.event_queue (
                        Event.AreaQuery { user_id; area_id = location_id }
                      ) in
                      
                      Lwt_result.return ()
                  | None -> 
                      Lwt_result.fail (Qed_error.DatabaseError "Client not found")
            end

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Character_selection_communication_system = struct
  (* Handles sending character selection responses to clients *)
  
  let handle_character_selected (state : State.t) user_id character =
    let client_opt = Connection_manager.find_client_by_user_id state.connection_manager user_id in
    match client_opt with
    | Some client ->
        begin
          try%lwt 
            let%lwt result = client.Client.send (Protocol.CharacterSelected { character }) in
            Lwt.return result
          with exn ->
            Stdio.eprintf "[ERROR] Exception sending CharacterSelected message: %s\n" (Printexc.to_string exn);
            Lwt.return_unit
        end
    | None -> 
        Stdio.eprintf "[ERROR] Client not found for user: %s when sending CharacterSelected\n" user_id;
        Lwt.return_unit

  let handle_character_selection_failed (state : State.t) user_id error =
    let client_opt = Connection_manager.find_client_by_user_id state.connection_manager user_id in
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
