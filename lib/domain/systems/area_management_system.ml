open Lwt.Syntax
open Base
open Error_utils

module Area_creation_system = struct
  let handle_create_area state user_id name description x y z ?elevation ?temperature ?moisture () =
    (* Create a new entity for the area *)
    let* entity_id_result = Ecs.Entity.create () in
    match entity_id_result with
    | Error e -> 
        Stdio.eprintf "Failed to create area entity: %s\n" (Error.to_string_hum e);
        (* Queue event for area creation failure *)
        let* () = State.enqueue state (Event.AreaCreationFailed {
          user_id;
          error = Qed_error.to_yojson (Qed_error.DatabaseError "Failed to create area entity") 
        }) in
        Lwt.return_unit
    | Ok entity_id ->
        let entity_id_str = Uuidm.to_string entity_id in
        
        (* Persist the new area in Tier-1 relational store using the newly generated id. *)
        let* area_result = Area.create ~id:entity_id_str ~name ~description ~x ~y ~z ?elevation ?temperature ?moisture () in
        match area_result with
        | Error e ->
            let* () = State.enqueue state (Event.AreaCreationFailed {
              user_id;
              error = Qed_error.to_yojson e
            }) in
            Lwt.return_unit
        | Ok _area_record ->
            (* Queue event for area creation success *)
            let* () = State.enqueue state (Event.AreaCreated {
              user_id;
              area_id = entity_id_str
            }) in
            Lwt.return_unit

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Area_creation_communication_system = struct
  let handle_area_created state user_id area_id =
    let open Lwt_result.Syntax in
    let* () = Publisher.publish_system_message_to_user state user_id (Printf.sprintf "Area created successfully with ID: %s" area_id) in
    Lwt_result.return ()

  let handle_area_creation_failed state user_id error =
    let open Lwt_result.Syntax in
    let* () = Publisher.publish_system_message_to_user state user_id (Yojson.Safe.to_string error) in
    Lwt_result.return ()

  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Exit_creation_system = struct
  let handle_create_exit state user_id from_area_id to_area_id direction =
    (* Validate from_area_id and to_area_id exist in the relational store *)
    let* from_area_valid =
      match%lwt Area.find_by_id from_area_id with
      | Ok _ -> Lwt.return true
      | Error _ -> Lwt.return false
    in

    let* to_area_valid =
      match%lwt Area.find_by_id to_area_id with
      | Ok _ -> Lwt.return true
      | Error _ -> Lwt.return false
    in
    
    if not (from_area_valid && to_area_valid) then begin
      (* One or both areas don't exist *)
      let* () = State.enqueue state (Event.ExitCreationFailed {
          user_id;
          error = Qed_error.to_yojson Qed_error.AreaNotFound
        }) in
      Lwt.return_unit
    end else begin
      (* Create exit and its reciprocal atomically *)
      let* exit_result = Exit.create
        ~from_area_id
        ~to_area_id
        ~direction
      in
      match exit_result with
      | Error e ->
          Stdio.eprintf "Failed to create exit pair: %s\n" (Qed_error.to_string e);
          let* () = State.enqueue state (Event.ExitCreationFailed {
              user_id;
              error = Qed_error.to_yojson e
            }) in
          Lwt.return_unit
      | Ok exit_record ->
          (* Queue event for exit creation success. The reciprocal is already created. *)
          let* () = State.enqueue state (Event.ExitCreated {
              user_id;
              exit_id = exit_record.id
            }) in
          Lwt.return_unit
    end

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Exit_creation_communication_system = struct
  let handle_exit_created state user_id exit_id =
    let open Lwt_result.Syntax in
    let* () = Publisher.publish_system_message_to_user state user_id (Printf.sprintf "Exit created successfully with ID: %s" exit_id) in
    Lwt_result.return ()

  let handle_exit_creation_failed state user_id error =
    let open Lwt_result.Syntax in
    let* () = Publisher.publish_system_message_to_user state user_id (Yojson.Safe.to_string error) in
    Lwt_result.return ()

  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Area_query_system = struct
  let find_characters_in_area area_id =
    let%lwt all_positions = Ecs.CharacterPositionStorage.all () in
    let char_entity_ids =
      List.filter all_positions ~f:(fun (_, pos) -> String.equal pos.area_id area_id)
      |> List.map ~f:fst
    in
    Lwt_list.filter_map_s (fun char_id ->
      let char_id_str = Uuidm.to_string char_id in
      match%lwt Character.find_by_id char_id_str with
      | Ok (Some char_record) ->
          Lwt.return_some (({ Types.id = char_id_str; name = char_record.name } : Types.list_character))
      | _ -> Lwt.return_none
    ) char_entity_ids

  (* Find all item entities in the specified area *)
  let find_items_in_area area_id =
    let%lwt item_positions = Ecs.ItemPositionStorage.all () in
    let entities_in_area =
      List.filter item_positions ~f:(fun (_, pos) -> String.equal pos.Components.ItemPositionComponent.area_id area_id)
      |> List.map ~f:fst
    in
    (* Fetch all item components first *)
    let%lwt item_comps =
      Lwt_list.filter_map_s (fun eid ->
        let%lwt comp_opt = Ecs.ItemStorage.get eid in
        Lwt.return (Option.map comp_opt ~f:(fun comp -> (eid, comp)))
      ) entities_in_area
    in
    let definition_ids = List.map item_comps ~f:(fun (_, comp) -> comp.Components.ItemComponent.item_definition_id) in
    let unique_definition_ids = List.dedup_and_sort ~compare:String.compare definition_ids in
    let%lwt items =
      let%lwt names_result = Item_definition.find_names_by_ids unique_definition_ids in
      match names_result with
      | Error _ ->
          (* fallback sequential lookup *)
          let* () = Lwt_io.printl (Printf.sprintf "[AreaQuery] Fallback lookup: %d" (List.length item_comps)) in
          Lwt_list.filter_map_s (fun (eid, comp) ->
            let%lwt def_res = Item_definition.find_by_id comp.Components.ItemComponent.item_definition_id in
            match def_res with
            | Ok (Some def) -> Lwt.return_some Types.{ id = Uuidm.to_string eid; name = def.name }
            | _ -> Lwt.return_none)
            item_comps
      | Ok pairs ->
          let name_map = Map.of_alist_exn (module String) pairs in
          let mapped = List.filter_map item_comps ~f:(fun (eid, comp) ->
            Map.find name_map comp.Components.ItemComponent.item_definition_id
            |> Option.map ~f:(fun name -> Types.{ id = Uuidm.to_string eid; name })) in
          Lwt.return mapped
    in
    Lwt.return items

  let handle_area_query state user_id area_id =
    let open Lwt_result.Syntax in
    (* Get area details *)
    match Uuidm.of_string area_id with
    | None ->
        let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[AreaQuery][Error] Invalid area_id: %s (user: %s)" area_id user_id)) in
        let* () = wrap_ok (State.enqueue state (Event.AreaQueryFailed {
            user_id;
            error = Qed_error.to_yojson Qed_error.AreaNotFound
          })) in
        Lwt_result.return ()
    | Some entity_id ->
        let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[AreaQuery][Debug] Converted area_id to entity_id: %s" (Uuidm.to_string entity_id))) in
        (* Fetch area data directly from relational store *)
        match%lwt Area.find_by_id area_id with
        | Error _e ->
            let* () = wrap_ok (State.enqueue state (Event.AreaQueryFailed {
                user_id;
                error = Qed_error.to_yojson Qed_error.AreaNotFound
              })) in
            Lwt_result.return ()
        | Ok area_model ->
            let* exits = Exit.find_by_area ~area_id in
            let exit_directions = List.map exits ~f:(fun exit ->
              Components.ExitComponent.direction_to_string exit.Exit.direction
            ) in
            let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[AreaQuery] Found area: %s (id: %s), exits: [%s]" area_model.name area_id (String.concat ~sep:", " exit_directions))) in
            let* items_here = wrap_val (find_items_in_area area_id) in
            let area_info : Types.area = {
              id = area_id;
              name = area_model.name;
              description = area_model.description;
              coordinate = Some { x = area_model.x; y = area_model.y; z = area_model.z };
              exits = List.map exit_directions ~f:(fun dir -> { Types.direction = dir });
              items = items_here;
              elevation = area_model.elevation;
              temperature = area_model.temperature;
              moisture = area_model.moisture;
            } in
            let* () = wrap_ok (State.enqueue state (Event.AreaQueryResult {
                user_id;
                area = area_info
              })) in
            let* () = wrap_ok (State.enqueue state (Event.RequestChatHistory { user_id; area_id })) in
            let* characters_here = wrap_val (find_characters_in_area area_id) in
            let* () = wrap_ok (Lwt_io.printl (Printf.sprintf "[AreaQuery] Characters present in area %s: %d" area_id (List.length characters_here))) in
            let* () = wrap_ok (State.enqueue state (Event.UpdateAreaPresence {
                area_id;
                characters = characters_here
              })) in
            Lwt_result.return ()

  let priority = 100

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end

module Area_query_communication_system = struct
  let handle_area_query_result state user_id area =
    let open Lwt_result.Syntax in
    let exits = List.map area.Types.exits ~f:(fun exit ->
      Schemas_generated.Output.{ direction = exit.Types.direction }
    ) in
    let items_pb = List.map area.Types.items ~f:(fun item ->
      (Schemas_generated.Output.{ id = item.Types.id; name = item.Types.name } : Schemas_generated.Output.area_item)
    ) in
    let area_update = Schemas_generated.Output.{
      area_id = area.Types.id;
      name = area.Types.name;
      description = area.Types.description;
      exits;
      items = items_pb;
    } in
    let output_event = Schemas_generated.Output.{
      target_user_ids = [user_id];
      payload = Area_update area_update;
      trace_id = "";
    } in
    let* () = Publisher.publish_event state output_event in
    Lwt_result.return ()

  let handle_area_query_failed state user_id error =
    let open Lwt_result.Syntax in
    let* () = Publisher.publish_system_message_to_user state user_id (Yojson.Safe.to_string error) in
    Lwt_result.return ()

  let priority = 50

  let execute () =
    (* This system doesn't need to run on every tick *)
    Lwt.return_unit
end 