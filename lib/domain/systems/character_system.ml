module Character_list_system = struct

  let handle_character_list_requested state user_id =
    match%lwt Ecs.CharacterStorage.all () with
    | [] ->
        (* No characters found, return an empty list *)
        let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
        (match client_opt with
        | Some client ->
            (* Send empty character list to the client *)
            client.Client.send (Protocol.CharacterList { characters = [] })
        | None -> Lwt.return_unit)
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
        
        (* Find the client associated with this user_id *)
        let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
        (match client_opt with
        | Some client ->
            (* Send the character list to the client *)
            client.Client.send (Protocol.CharacterList { characters = characters })
        | None ->
            (* User not connected, nothing to do *)
            Lwt.return_unit)

  (* System implementation for ECS *)
  let priority = 100

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
        
        (* Find the client and update state/send response *)
        let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
        match client_opt with
        | Some client ->
            (* Update client state *)
            Client.set_character client entity_id_str;
            Connection_manager.add_to_room state.State.connection_manager 
              ~client_id:client.Client.id 
              ~room_id:starting_area_id;
            (* Send response to client *)
            let list_character : Types.list_character = {
              id = entity_id_str;
              name = name;
            } in  
            let%lwt () = client.Client.send (Protocol.CharacterCreated { character = list_character }) in
            (* TODO: Send initial area info *)
            Lwt.return_unit
        | None -> Lwt.return_unit

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 

module Character_selection_system = struct
  let handle_character_selected state user_id character_id =
    (* Check if character exists and belongs to the user *)
    match Uuidm.of_string character_id with
    | None ->
        Stdio.eprintf "Invalid character ID format: %s\n" character_id;
        Lwt.return_unit
    | Some entity_id ->
        (* Get character component to verify ownership *)
        match%lwt Ecs.CharacterStorage.get entity_id with
        | None ->
            (* Character not found *)
            let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
            (match client_opt with
            | Some client ->
                client.Client.send (Protocol.CharacterSelectionFailed 
                  { error = Qed_error.to_yojson Qed_error.CharacterNotFound })
            | None -> Lwt.return_unit)
        | Some char_comp ->
            if not (String.equal char_comp.Components.CharacterComponent.user_id user_id) then
              (* Character doesn't belong to this user *)
              let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
              (match client_opt with
              | Some client ->
                  client.Client.send (Protocol.CharacterSelectionFailed 
                    { error = Qed_error.to_yojson (Qed_error.InvalidCharacter) })
              | None -> Lwt.return_unit)
            else
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
                  let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
                  (match client_opt with
                  | Some client ->
                      client.Client.send (Protocol.CharacterSelectionFailed 
                        { error = Qed_error.to_yojson (Qed_error.DatabaseError "Character data is incomplete") })
                  | None -> Lwt.return_unit)
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
                  let client_opt = Connection_manager.find_client_by_user_id state.State.connection_manager user_id in
                  (match client_opt with
                  | Some client ->
                      (* Update client state *)
                      Client.set_character client character_id;
                      
                      (* Add to character's current room *)
                      Connection_manager.add_to_room state.State.connection_manager
                        ~client_id:client.Client.id
                        ~room_id:location_id;
                      
                      (* Create a protocol character from the model *)
                      let%lwt () = client.Client.send 
                        (Protocol.CharacterSelected { character = character }) in
                      
                      (* TODO: Send area info *)
                      (* This would normally call something like send_area_info *)
                      
                      Lwt.return_unit
                  | None -> Lwt.return_unit)

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end
