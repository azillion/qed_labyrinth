(* This file contains both character system and character communication system modules *)

module Character_list_system = struct

  let handle_character_list_requested state user_id =
    match%lwt Ecs.CharacterStorage.all () with
    | [] ->
        (* No characters found, queue an empty list event *)
        let%lwt () = Infra.Queue.push state.State.event_queue (Event.SendCharacterList { user_id; characters = [] }) in
        Lwt.return_unit
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
        Lwt.return_unit

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
  let handle_create_character state user_id name description starting_area_id =
    (* Create a new entity *)
    let%lwt entity_id_result = Ecs.Entity.create () in
    match entity_id_result with
    | Error e -> 
        Stdio.eprintf "Failed to create entity: %s\n" (Base.Error.to_string_hum e);
        (* Queue event for creation failure *)
        let%lwt () = Infra.Queue.push state.State.event_queue (
          Event.SendCharacterCreationFailed { 
            user_id; 
            error = Qed_error.to_yojson (Qed_error.DatabaseError "Failed to create entity") 
          }
        ) in
        Lwt.return_unit
    | Ok entity_id ->
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
        let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
        match client_opt with
        | Some client ->
            (* Update client state *)
            Client.set_character client entity_id_str;
            Connection_manager.add_to_room state.State.connection_manager 
              ~client_id:client.Client.id 
              ~room_id:starting_area_id;
            
            (* Queue an event to send response to client *)
            let list_character : Types.list_character = {
              id = entity_id_str;
              name
            } in  
            let%lwt () = Infra.Queue.push state.State.event_queue (
              Event.SendCharacterCreated { user_id; character = list_character }
            ) in
            (* Send initial area info using AreaQuery event *)
            let%lwt () = Infra.Queue.push state.State.event_queue (
              Event.AreaQuery { user_id; area_id = starting_area_id }
            ) in
            Lwt.return_unit
        | None -> Lwt.return_unit

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
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Character_selection_system = struct
  let handle_character_selected state user_id character_id =
    Stdio.printf "[DEBUG] Character selection initiated: user=%s, character=%s\n" user_id character_id;
    (* Check if character exists and belongs to the user *)
    match Uuidm.of_string character_id with
    | None ->
        Stdio.eprintf "[ERROR] Invalid character ID format: %s\n" character_id;
        let%lwt () = Infra.Queue.push state.State.event_queue (
          Event.SendCharacterSelectionFailed { 
            user_id; 
            error = Qed_error.to_yojson (Qed_error.InvalidCharacter) 
          }
        ) in
        Lwt.return_unit
    | Some entity_id ->
        Stdio.printf "[DEBUG] Character ID parsed successfully: %s\n" (Uuidm.to_string entity_id);
        (* Get character component to verify ownership *)
        match%lwt Ecs.CharacterStorage.get entity_id with
        | None ->
            (* Character not found *)
            Stdio.eprintf "[ERROR] Character not found with ID: %s\n" character_id;
            let%lwt () = Infra.Queue.push state.State.event_queue (
              Event.SendCharacterSelectionFailed { 
                user_id; 
                error = Qed_error.to_yojson (Qed_error.CharacterNotFound) 
              }
            ) in
            Lwt.return_unit
        | Some char_comp ->
            Stdio.printf "[DEBUG] Character found, checking ownership. Character user: %s, Request user: %s\n" 
              char_comp.Components.CharacterComponent.user_id user_id;
            if not (String.equal char_comp.Components.CharacterComponent.user_id user_id) then begin
              (* Character doesn't belong to this user *)
              Stdio.eprintf "[ERROR] Character %s doesn't belong to user %s\n" character_id user_id;
              let%lwt () = Infra.Queue.push state.State.event_queue (
                Event.SendCharacterSelectionFailed { 
                  user_id; 
                  error = Qed_error.to_yojson (Qed_error.InvalidCharacter) 
                }
              ) in
              Lwt.return_unit
            end else begin
              Stdio.printf "[DEBUG] Character ownership verified\n";
              (* Character is valid and belongs to the user *)
              (* Get description and position components *)
              let%lwt desc_opt = Ecs.DescriptionStorage.get entity_id in
              let%lwt pos_opt = Ecs.CharacterPositionStorage.get entity_id in
              
              Stdio.printf "[DEBUG] Description component exists: %b, Position component exists: %b\n"
                (Option.is_some desc_opt) (Option.is_some pos_opt);
              
              (* Find current location *)
              let location_id = match pos_opt with
                | Some pos -> 
                    let area_id = pos.Components.CharacterPositionComponent.area_id in
                    Stdio.printf "[DEBUG] Character position found, area_id: %s\n" area_id;
                    area_id
                | None -> 
                    Stdio.printf "[DEBUG] Character position not found, using default area\n";
                    "00000000-0000-0000-0000-000000000000" (* Default starting area *)
              in
              
              (* Get the name from description *)
              match desc_opt with
              | None ->
                  (* Missing description component *)
                  Stdio.eprintf "[ERROR] Missing description component for character: %s\n" character_id;
                  let%lwt () = Infra.Queue.push state.State.event_queue (
                    Event.SendCharacterSelectionFailed { 
                      user_id; 
                      error = Qed_error.to_yojson (Qed_error.DatabaseError "Character data is incomplete") 
                    }
                  ) in
                  Lwt.return_unit
              | Some desc ->
                  Stdio.printf "[DEBUG] Character name: %s\n" desc.Components.DescriptionComponent.name;
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
                  let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
                  match client_opt with
                  | Some client ->
                      Stdio.printf "[DEBUG] Client found for user: %s\n" user_id;
                      (* Update client state *)
                      (try 
                        Client.set_character client character_id;
                        Stdio.printf "[DEBUG] Client character set to: %s\n" character_id;
                      with e -> 
                        Stdio.eprintf "[ERROR] Exception in set_character: %s\n" (Printexc.to_string e));
                      
                      (* Add to character's current room *)
                      (try
                        Connection_manager.add_to_room state.State.connection_manager
                          ~client_id:client.Client.id
                          ~room_id:location_id;
                        Stdio.printf "[DEBUG] Client added to room: %s\n" location_id;
                      with e ->
                        Stdio.eprintf "[ERROR] Exception in add_to_room: %s\n" (Printexc.to_string e));
                      
                      (* Queue event to send character data to client *)
                      let%lwt () = 
                        try%lwt
                          let%lwt result = Infra.Queue.push state.State.event_queue (
                            Event.SendCharacterSelected { user_id; character }
                          ) in
                          Stdio.printf "[DEBUG] SendCharacterSelected event queued\n";
                          Lwt.return result
                        with e ->
                          Stdio.eprintf "[ERROR] Exception when pushing SendCharacterSelected: %s\n" (Printexc.to_string e);
                          Lwt.return_unit
                      in
                      
                      (* Send area info using AreaQuery event *)
                      let%lwt () = 
                        try%lwt
                          let%lwt result = Infra.Queue.push state.State.event_queue (
                            Event.AreaQuery { user_id; area_id = location_id }
                          ) in
                          Stdio.printf "[DEBUG] AreaQuery event queued: %s\n" location_id;
                          Lwt.return result
                        with e ->
                          Stdio.eprintf "[ERROR] Exception when pushing AreaQuery: %s\n" (Printexc.to_string e);
                          Lwt.return_unit
                      in
                      
                      Stdio.printf "[DEBUG] Character selection completed successfully\n";
                      Lwt.return_unit
                  | None -> 
                      Stdio.eprintf "[ERROR] Client not found for user: %s\n" user_id;
                      Lwt.return_unit
            end

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Character_selection_communication_system = struct
  (* Handles sending character selection responses to clients *)
  
  let handle_character_selected state user_id character =
    (* Type checking: character should be of type Types.character *)
    Stdio.printf "[DEBUG] Handling character selected event for user_id: %s\n" user_id;
    
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        Stdio.printf "[DEBUG] Client found, sending CharacterSelected message\n";
        begin
          try%lwt 
            let%lwt result = client.Client.send (Protocol.CharacterSelected { character }) in
            Stdio.printf "[DEBUG] CharacterSelected message sent successfully\n";
            Lwt.return result
          with exn ->
            Stdio.eprintf "[ERROR] Exception sending CharacterSelected message: %s\n" (Printexc.to_string exn);
            Lwt.return_unit
        end
    | None -> 
        Stdio.eprintf "[ERROR] Client not found for user: %s when sending CharacterSelected\n" user_id;
        Lwt.return_unit

  let handle_character_selection_failed state user_id error =
    Stdio.printf "[DEBUG] Handling character selection failed event for user %s\n" user_id;
    let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
    match client_opt with
    | Some client ->
        Stdio.printf "[DEBUG] Client found, sending CharacterSelectionFailed message\n";
        begin
          try%lwt
            let%lwt result = client.Client.send (Protocol.CharacterSelectionFailed { error }) in
            Stdio.printf "[DEBUG] CharacterSelectionFailed message sent successfully\n";
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
