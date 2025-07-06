open Lwt.Syntax
open Base

module Area_creation_system = struct
  let handle_create_area state user_id name description x y z ?elevation ?temperature ?moisture () =
    (* Create a new entity for the area *)
    let* entity_id_result = Ecs.Entity.create () in
    match entity_id_result with
    | Error e -> 
        Stdio.eprintf "Failed to create area entity: %s\n" (Error.to_string_hum e);
        (* Queue event for area creation failure *)
        let* () = Infra.Queue.push state.State.event_queue (
          Event.AreaCreationFailed { 
            user_id;
            error = Qed_error.to_yojson (Qed_error.DatabaseError "Failed to create area entity") 
          }
        ) in
        Lwt.return_unit
    | Ok entity_id ->
        let entity_id_str = Uuidm.to_string entity_id in
        
        (* Add AreaComponent *)
        let area_comp = Components.AreaComponent.{ 
          entity_id = entity_id_str;
          x;
          y;
          z;
          elevation;
          temperature;
          moisture;
        } in
        let* () = Ecs.AreaStorage.set entity_id area_comp in
        
        (* Add DescriptionComponent *)
        let desc_comp = Components.DescriptionComponent.{ 
          entity_id = entity_id_str;
          name; 
          description = Some description 
        } in
        let* () = Ecs.DescriptionStorage.set entity_id desc_comp in
        
        (* Queue event for area creation success *)
        let* () = Infra.Queue.push state.State.event_queue (
          Event.AreaCreated {
            user_id;
            area_id = entity_id_str
          }
        ) in
        Lwt.return_unit

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Area_creation_communication_system = struct
  let handle_area_created state user_id area_id =
    Publisher.publish_system_message_to_user state user_id (Printf.sprintf "Area created successfully with ID: %s" area_id)

  let handle_area_creation_failed state user_id error =
    Publisher.publish_system_message_to_user state user_id (Yojson.Safe.to_string error)

  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Exit_creation_system = struct
  let handle_create_exit state user_id from_area_id to_area_id direction description hidden locked =
    (* Validate from_area_id and to_area_id exist *)
    let* from_area_valid = match Uuidm.of_string from_area_id with
      | None -> Lwt.return false
      | Some entity_id -> 
          let* area_opt = Ecs.AreaStorage.get entity_id in
          Lwt.return (Option.is_some area_opt)
    in
    
    let* to_area_valid = match Uuidm.of_string to_area_id with
      | None -> Lwt.return false
      | Some entity_id -> 
          let* area_opt = Ecs.AreaStorage.get entity_id in
          Lwt.return (Option.is_some area_opt)
    in
    
    if not (from_area_valid && to_area_valid) then begin
      (* One or both areas don't exist *)
      let* () = Infra.Queue.push state.State.event_queue (
        Event.ExitCreationFailed {
          user_id;
          error = Qed_error.to_yojson Qed_error.AreaNotFound
        }
      ) in
      Lwt.return_unit
    end else begin
      (* Create a new entity for the exit *)
      let* entity_id_result = Ecs.Entity.create () in
      match entity_id_result with
      | Error e -> 
          Stdio.eprintf "Failed to create exit entity: %s\n" (Error.to_string_hum e);
          let* () = Infra.Queue.push state.State.event_queue (
            Event.ExitCreationFailed {
              user_id;
              error = Qed_error.to_yojson (Qed_error.DatabaseError "Failed to create exit entity")
            }
          ) in
          Lwt.return_unit
      | Ok entity_id ->
          let entity_id_str = Uuidm.to_string entity_id in
          
          (* Add ExitComponent *)
          let exit_comp = Components.ExitComponent.{
            entity_id = entity_id_str;
            from_area_id;
            to_area_id;
            direction;
            description;
            hidden;
            locked;
          } in
          let* () = Ecs.ExitStorage.set entity_id exit_comp in
          
          (* Queue event for exit creation success *)
          let* () = Infra.Queue.push state.State.event_queue (
            Event.ExitCreated {
              user_id;
              exit_id = entity_id_str
            }
          ) in
          
          (* Create reciprocal exit automatically if not hidden *)
          if not hidden then begin
            let* entity_id_result = Ecs.Entity.create () in
            match entity_id_result with
            | Error e -> 
                Stdio.eprintf "Failed to create reciprocal exit entity: %s\n" (Error.to_string_hum e);
                Lwt.return_unit
            | Ok recip_entity_id ->
                let recip_entity_id_str = Uuidm.to_string recip_entity_id in
                
                (* Add ExitComponent for reciprocal exit *)
                let recip_exit_comp = Components.ExitComponent.{
                  entity_id = recip_entity_id_str;
                  from_area_id = to_area_id;  (* Swapped *)
                  to_area_id = from_area_id;  (* Swapped *)
                  direction = Components.ExitComponent.opposite_direction direction;
                  description;  (* Same description *)
                  hidden;       (* Same hidden value *)
                  locked;       (* Same locked value *)
                } in
                let* () = Ecs.ExitStorage.set recip_entity_id recip_exit_comp in
                Lwt.return_unit
          end else
            Lwt.return_unit
    end

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Exit_creation_communication_system = struct
  let handle_exit_created state user_id exit_id =
    Publisher.publish_system_message_to_user state user_id (Printf.sprintf "Exit created successfully with ID: %s" exit_id)

  let handle_exit_creation_failed state user_id error =
    Publisher.publish_system_message_to_user state user_id (Yojson.Safe.to_string error)

  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Area_query_system = struct
  let find_characters_in_area area_id =
    let%lwt all_positions = Ecs.CharacterPositionStorage.all () in
    let characters_in_area =
      List.filter all_positions ~f:(fun (_, pos) -> String.equal pos.area_id area_id)
      |> List.map ~f:fst
    in
    let%lwt char_details =
      Lwt_list.map_s (fun char_id ->
        let%lwt name_opt =
          let%lwt desc_opt = Ecs.DescriptionStorage.get char_id in
          Lwt.return (Option.map desc_opt ~f:(fun d -> d.name))
        in
        Lwt.return (Option.map name_opt ~f:(fun name -> { Types.id = Uuidm.to_string char_id; name }))
      ) characters_in_area
    in
    Lwt.return (List.filter_opt char_details)

  let handle_area_query state user_id area_id =
    let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery] Called by user %s for area %s" user_id area_id) in
    (* Get area details *)
    match Uuidm.of_string area_id with
    | None ->
        let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery][Error] Invalid area_id: %s (user: %s)" area_id user_id) in
        let* () = Infra.Queue.push state.State.event_queue (
          Event.AreaQueryFailed {
            user_id;
            error = Qed_error.to_yojson Qed_error.AreaNotFound
          }
        ) in
        Lwt.return_unit
    | Some entity_id ->
        let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery][Debug] Converted area_id to entity_id: %s" (Uuidm.to_string entity_id)) in
        let* area_opt = Ecs.AreaStorage.get entity_id in
        let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery][Debug] AreaStorage.get result: %s" (match area_opt with Some _ -> "Found" | None -> "Not found")) in
        let* desc_opt = Ecs.DescriptionStorage.get entity_id in
        let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery][Debug] DescriptionStorage.get result: %s" (match desc_opt with Some _ -> "Found" | None -> "Not found")) in
        (match (area_opt, desc_opt) with
        | (Some area, Some desc) ->
            let* all_exits = Ecs.ExitStorage.all () in
            let exits = List.filter all_exits ~f:(fun (_, exit_comp) ->
              String.equal exit_comp.Components.ExitComponent.from_area_id area_id &&
              not exit_comp.Components.ExitComponent.hidden
            ) in
            let exit_directions = List.map exits ~f:(fun (_, exit) ->
              Components.ExitComponent.direction_to_string exit.Components.ExitComponent.direction
            ) in
            let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery] Found area: %s (id: %s), exits: [%s]" desc.Components.DescriptionComponent.name area_id (String.concat ~sep:", " exit_directions)) in
            let area_info : Types.area = {
              id = area_id;
              name = desc.Components.DescriptionComponent.name;
              description = Option.value desc.Components.DescriptionComponent.description ~default:"";
              coordinate = Some {
                x = area.Components.AreaComponent.x;
                y = area.Components.AreaComponent.y;
                z = area.Components.AreaComponent.z;
              };
              exits = List.map exit_directions ~f:(fun dir -> { Types.direction = dir });
              elevation = area.Components.AreaComponent.elevation;
              temperature = area.Components.AreaComponent.temperature;
              moisture = area.Components.AreaComponent.moisture;
            } in
            let* () = Infra.Queue.push state.State.event_queue (
              Event.AreaQueryResult {
                user_id;
                area = area_info
              }
            ) in
            let* () = Infra.Queue.push state.State.event_queue
              (Event.RequestChatHistory { user_id; area_id })
            in
            let%lwt characters_here = find_characters_in_area area_id in
            let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery] Characters present in area %s: %d" area_id (List.length characters_here)) in
            let* () = Infra.Queue.push state.State.event_queue (
              Event.UpdateAreaPresence {
                area_id;
                characters = characters_here
              }
            ) in
            Lwt.return_unit
        | _ ->
            let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery][Error] Area or description not found for area_id: %s (user: %s)" area_id user_id) in
            let* () = Infra.Queue.push state.State.event_queue (
              Event.AreaQueryFailed {
                user_id;
                error = Qed_error.to_yojson Qed_error.AreaNotFound
              }
            ) in
            Lwt.return_unit)

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Area_query_communication_system = struct
  let handle_area_query_result state user_id area =
    let exits = List.map area.Types.exits ~f:(fun exit ->
      Schemas_generated.Output.{ direction = exit.Types.direction }
    ) in
    let area_update = Schemas_generated.Output.{
      area_id = area.Types.id;
      name = area.Types.name;
      description = area.Types.description;
      exits;
    } in
    let output_event = Schemas_generated.Output.{
      target_user_ids = [user_id];
      payload = Area_update area_update;
    } in
    Publisher.publish_event state output_event

  let handle_area_query_failed state user_id error =
    Publisher.publish_system_message_to_user state user_id (Yojson.Safe.to_string error)

  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 