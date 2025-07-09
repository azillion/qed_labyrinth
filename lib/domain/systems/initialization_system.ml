open Lwt.Syntax
open Base

module Starting_area_initialization_system = struct
  let initialize_starting_area () =
    let starting_area_id = "00000000-0000-0000-0000-000000000000" in
    
    (* First check if we already have the area in our ECS system *)
    let* existing_area = match Uuidm.of_string starting_area_id with
      | None -> Lwt.return None
      | Some entity_id -> Ecs.AreaStorage.get entity_id
    in
    
    (* If the area already exists in our ECS, do nothing *)
    match existing_area with
    | Some _ -> Lwt.return_unit
    | None ->
        (* The starting area doesn't exist in our ECS yet, we need to add it *)
        match Uuidm.of_string starting_area_id with
        | None -> 
            let* () = Lwt_io.printl "Invalid starting area UUID format" in
            Lwt.return_unit
        | Some entity_id ->
            (* Create predefined starting area instead of looking it up *)
            (* Create AreaComponent *)
            let area_comp = Components.AreaComponent.{
              entity_id = starting_area_id;
              x = 0;
              y = 0;
              z = 0;
              elevation = Some 0.0;
              temperature = Some 0.0;
              moisture = Some 0.0;
            } in
            
            (* Create DescriptionComponent *)
            let desc_comp = Components.DescriptionComponent.{
              entity_id = starting_area_id;
              name = "The Ancient Oak Meadow";
              description = Some "An ancient oak dominates the hillside, its twisted trunk rising from the earth in massive coils. The tree's vast canopy spreads across the sky, its leaves catching rays of sunlight that pierce through gathering storm clouds above.\nThe meadow blooms with blue cornflowers and crimson poppies dotting the emerald grass.";
            } in
            
            (* Add the entity to the entities table *)
            let db_operation (module Db : Caqti_lwt.CONNECTION) =
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
                  "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING")
                starting_area_id
              in
              
              (* Directly insert into the areas table *)
              let area_json = area_comp |> [%to_yojson: Components.AreaComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT INTO area_components (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO UPDATE SET data = EXCLUDED.data")
                (starting_area_id, area_json)
              in
              
              (* Directly insert into the descriptions table *)
              let desc_json = desc_comp |> [%to_yojson: Components.DescriptionComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT INTO descriptions (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO UPDATE SET data = EXCLUDED.data")
                (starting_area_id, desc_json)
              in
              
              (* Also insert into the relational areas table for foreign key references *)
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t6 string string string int int int) ->. Caqti_type.unit)
                  "INSERT INTO areas (id, name, description, x, y, z) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING")
                (starting_area_id, "The Ancient Oak Meadow", 
                 "An ancient oak dominates the hillside, its twisted trunk rising from the earth in massive coils. The tree's vast canopy spreads across the sky, its leaves catching rays of sunlight that pierce through gathering storm clouds above.\nThe meadow blooms with blue cornflowers and crimson poppies dotting the emerald grass.",
                 0, 0, 0)
              in
              
              Lwt.return_ok ()
            in
            
            let* entity_result = Infra.Database.Pool.use db_operation in
            match entity_result with
            | Error e ->
                let* () = Lwt_io.printl (Printf.sprintf "Failed to create entity for starting area: %s" (Error.to_string_hum e)) in
                Lwt.return_unit
            | Ok () ->
                (* Ensure the entity is registered in the ECS entity catalogue before adding components *)
                let* _ = Ecs.Entity.ensure_exists entity_id in
                (* Add the components to our ECS storage *)
                let* () = Ecs.AreaStorage.set entity_id area_comp in
                let* () = Ecs.DescriptionStorage.set entity_id desc_comp in
                
                let* () = Lwt_io.printl "Successfully initialized starting area in ECS" in
                Lwt.return_unit

  let initialize_second_area () =
    let second_area_id = "11111111-1111-1111-1111-111111111111" in
    
    (* First check if we already have the area in our ECS system *)
    let* existing_area = match Uuidm.of_string second_area_id with
      | None -> Lwt.return None
      | Some entity_id -> Ecs.AreaStorage.get entity_id
    in
    
    (* If the area already exists in our ECS, do nothing *)
    match existing_area with
    | Some _ -> Lwt.return_unit
    | None ->
        (* The second area doesn't exist in our ECS yet, we need to add it *)
        match Uuidm.of_string second_area_id with
        | None -> 
            let* () = Lwt_io.printl "Invalid second area UUID format" in
            Lwt.return_unit
        | Some entity_id ->
            (* Create predefined second area *)
            (* Create AreaComponent *)
            let area_comp = Components.AreaComponent.{
              entity_id = second_area_id;
              x = 0;
              y = 1;
              z = 0;
              elevation = Some 0.0;
              temperature = Some 0.0;
              moisture = Some 0.0;
            } in
            
            (* Create DescriptionComponent *)
            let desc_comp = Components.DescriptionComponent.{
              entity_id = second_area_id;
              name = "The Whispering Grove";
              description = Some "A dense grove of ancient trees stands before you, their branches intertwined like the fingers of old friends. The air is thick with the scent of pine and earth, and a gentle breeze carries whispers through the leaves. Sunlight filters through the canopy in golden shafts, illuminating patches of moss-covered ground where small flowers bloom in the shadows.";
            } in
            
            (* Add the entity to the entities table *)
            let db_operation (module Db : Caqti_lwt.CONNECTION) =
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
                  "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING")
                second_area_id
              in
              
              (* Directly insert into the areas table *)
              let area_json = area_comp |> [%to_yojson: Components.AreaComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT INTO area_components (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO UPDATE SET data = EXCLUDED.data")
                (second_area_id, area_json)
              in
              
              (* Directly insert into the descriptions table *)
              let desc_json = desc_comp |> [%to_yojson: Components.DescriptionComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT INTO descriptions (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO UPDATE SET data = EXCLUDED.data")
                (second_area_id, desc_json)
              in
              
              (* Also insert into the relational areas table for foreign key references *)
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t6 string string string int int int) ->. Caqti_type.unit)
                  "INSERT INTO areas (id, name, description, x, y, z) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING")
                (second_area_id, "The Whispering Grove", 
                 "A dense grove of ancient trees stands before you, their branches intertwined like the fingers of old friends. The air is thick with the scent of pine and earth, and a gentle breeze carries whispers through the leaves. Sunlight filters through the canopy in golden shafts, illuminating patches of moss-covered ground where small flowers bloom in the shadows.",
                 0, 1, 0)
              in
              
              Lwt.return_ok ()
            in
            
            let* entity_result = Infra.Database.Pool.use db_operation in
            match entity_result with
            | Error e ->
                let* () = Lwt_io.printl (Printf.sprintf "Failed to create entity for second area: %s" (Error.to_string_hum e)) in
                Lwt.return_unit
            | Ok () ->
                (* Ensure the entity is registered in the ECS entity catalogue before adding components *)
                let* _ = Ecs.Entity.ensure_exists entity_id in
                (* Add the components to our ECS storage *)
                let* () = Ecs.AreaStorage.set entity_id area_comp in
                let* () = Ecs.DescriptionStorage.set entity_id desc_comp in
                
                let* () = Lwt_io.printl "Successfully initialized second area in ECS" in
                Lwt.return_unit

  let create_area_connection () =
    let starting_area_id = "00000000-0000-0000-0000-000000000000" in
    let second_area_id = "11111111-1111-1111-1111-111111111111" in
    
    (* Check if the exit already exists *)
    let* all_exits = Ecs.ExitStorage.all () in
    let exit_exists = List.exists all_exits ~f:(fun (_, exit_comp) ->
      String.equal exit_comp.Components.ExitComponent.from_area_id starting_area_id &&
      String.equal exit_comp.Components.ExitComponent.to_area_id second_area_id &&
      phys_equal exit_comp.Components.ExitComponent.direction Components.ExitComponent.North
    ) in
    
    if exit_exists then
      Lwt.return_unit
    else
      (* Create exit from starting area to second area (North) *)
      let* exit_entity_id_result = Ecs.Entity.create () in
      match exit_entity_id_result with
      | Error e ->
          let* () = Lwt_io.printl (Printf.sprintf "Failed to create exit entity: %s" (Error.to_string_hum e)) in
          Lwt.return_unit
      | Ok exit_entity_id ->
          let exit_entity_id_str = Uuidm.to_string exit_entity_id in
          
          (* Create exit from starting area to second area *)
          let exit_comp = Components.ExitComponent.{
            entity_id = exit_entity_id_str;
            from_area_id = starting_area_id;
            to_area_id = second_area_id;
            direction = Components.ExitComponent.North;
            description = Some "A winding path leads north through the meadow toward a dense grove of trees.";
            hidden = false;
            locked = false;
          } in
          
          (* Create reciprocal exit from second area to starting area *)
          let* recip_exit_entity_id_result = Ecs.Entity.create () in
          match recip_exit_entity_id_result with
          | Error e ->
              let* () = Lwt_io.printl (Printf.sprintf "Failed to create reciprocal exit entity: %s" (Error.to_string_hum e)) in
              Lwt.return_unit
          | Ok recip_exit_entity_id ->
              let recip_exit_entity_id_str = Uuidm.to_string recip_exit_entity_id in
              
              let recip_exit_comp = Components.ExitComponent.{
                entity_id = recip_exit_entity_id_str;
                from_area_id = second_area_id;
                to_area_id = starting_area_id;
                direction = Components.ExitComponent.South;
                description = Some "A winding path leads south through the grove toward an open meadow.";
                hidden = false;
                locked = false;
              } in
              
              (* Add exits to database and ECS *)
              let db_operation (module Db : Caqti_lwt.CONNECTION) =
                (* Insert exit entities *)
                let* _ = Db.exec 
                  (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
                    "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING")
                  exit_entity_id_str
                in
                let* _ = Db.exec 
                  (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
                    "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING")
                  recip_exit_entity_id_str
                in
                
                (* Insert exit data *)
                let exit_json = exit_comp |> [%to_yojson: Components.ExitComponent.t] |> Yojson.Safe.to_string in
                let* _ = Db.exec 
                  (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                    "INSERT INTO exits (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO UPDATE SET data = EXCLUDED.data")
                  (exit_entity_id_str, exit_json)
                in
                
                let recip_exit_json = recip_exit_comp |> [%to_yojson: Components.ExitComponent.t] |> Yojson.Safe.to_string in
                let* _ = Db.exec 
                  (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                    "INSERT INTO exits (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO UPDATE SET data = EXCLUDED.data")
                  (recip_exit_entity_id_str, recip_exit_json)
                in
                
                Lwt.return_ok ()
              in
              
              let* db_result = Infra.Database.Pool.use db_operation in
              match db_result with
              | Error e ->
                  let* () = Lwt_io.printl (Printf.sprintf "Failed to create exits in database: %s" (Error.to_string_hum e)) in
                  Lwt.return_unit
              | Ok () ->
                  (* Add to ECS storage *)
                  let* () = Ecs.ExitStorage.set exit_entity_id exit_comp in
                  let* () = Ecs.ExitStorage.set recip_exit_entity_id recip_exit_comp in
                  
                  let* () = Lwt_io.printl "Successfully created area connection" in
                  Lwt.return_unit

  let priority = 10  (* Run this early in the startup process *)

  (* Run initialization once at startup *)
  let initialize_starting_area_once () =
    let open Lwt.Syntax in
    let* () = Lwt_io.printl "Initializing starting area" in
    let* () = initialize_starting_area () in
    let* () = Lwt_io.printl "Initializing second area" in
    let* () = initialize_second_area () in
    let* () = Lwt_io.printl "Creating area connection" in
    create_area_connection ()

  (* Execute function no longer performs initialization *)
  let execute () = Lwt.return_unit
end 