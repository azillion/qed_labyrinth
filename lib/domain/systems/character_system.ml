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
        let%lwt characters_with_details = Lwt_list.map_s (fun (entity_id, char_component) ->
          let%lwt desc_opt = Ecs.DescriptionStorage.get entity_id in
          let%lwt pos_opt = Ecs.CharacterPositionStorage.get entity_id in
          
          match desc_opt with
          | Some desc -> 
              let location_id = match pos_opt with
                | Some pos -> pos.Components.CharacterPositionComponent.area_id
                | None -> "00000000-0000-0000-0000-000000000000" (* Default starting area *)
              in
              
              Lwt.return (Some {
                Character.id = Uuidm.to_string entity_id;
                user_id = char_component.Components.CharacterComponent.user_id;
                name = desc.Components.DescriptionComponent.name;
                location_id = location_id;
                health = 100; (* Default values since we're primarily using id and name *)
                max_health = 100;
                mana = 100;
                max_mana = 100;
                level = 1;
                experience = 0;
                created_at = Ptime_clock.now (); (* Current time as placeholder *)
                deleted_at = None
              })
          | None -> Lwt.return None
        ) user_characters in
        
        (* Filter out None values and convert to protocol format *)
        let characters = 
          Base.List.filter_map characters_with_details ~f:(fun char_opt -> char_opt)
          |> Base.List.map ~f:Types.character_of_model 
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
            Connection_manager.add_to_room state.connection_manager 
              ~client_id:client.Client.id 
              ~room_id:starting_area_id;
            (* Send response to client *)
            let character = { Types.id = entity_id_str; name } in
            let%lwt () = client.Client.send (Protocol.CharacterCreated (Types.character_to_yojson character)) in
            (* TODO: Send initial area info *)
            Lwt.return_unit
        | None -> Lwt.return_unit

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 
