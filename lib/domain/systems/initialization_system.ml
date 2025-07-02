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
            Stdio.eprintf "Invalid starting area UUID format\n";
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
                  "INSERT OR IGNORE INTO entities (id) VALUES (?)")
                starting_area_id
              in
              
              (* Directly insert into the areas table *)
              let area_json = area_comp |> [%to_yojson: Components.AreaComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT OR REPLACE INTO areas (entity_id, data) VALUES (?, ?)")
                (starting_area_id, area_json)
              in
              
              (* Directly insert into the descriptions table *)
              let desc_json = desc_comp |> [%to_yojson: Components.DescriptionComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT OR REPLACE INTO descriptions (entity_id, data) VALUES (?, ?)")
                (starting_area_id, desc_json)
              in
              
              Lwt.return_ok ()
            in
            
            let* entity_result = Infra.Database.Pool.use db_operation in
            match entity_result with
            | Error e ->
                Stdio.eprintf "Failed to create entity for starting area: %s\n" (Error.to_string_hum e);
                Lwt.return_unit
            | Ok () ->
                (* Add the components to our ECS storage *)
                let* () = Ecs.AreaStorage.set entity_id area_comp in
                let* () = Ecs.DescriptionStorage.set entity_id desc_comp in
                
                Stdio.printf "Successfully initialized starting area in ECS\n";
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
            Stdio.eprintf "Invalid second area UUID format\n";
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
                  "INSERT OR IGNORE INTO entities (id) VALUES (?)")
                second_area_id
              in
              
              (* Directly insert into the areas table *)
              let area_json = area_comp |> [%to_yojson: Components.AreaComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT OR REPLACE INTO areas (entity_id, data) VALUES (?, ?)")
                (second_area_id, area_json)
              in
              
              (* Directly insert into the descriptions table *)
              let desc_json = desc_comp |> [%to_yojson: Components.DescriptionComponent.t] |> Yojson.Safe.to_string in
              let* _ = Db.exec 
                (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                  "INSERT OR REPLACE INTO descriptions (entity_id, data) VALUES (?, ?)")
                (second_area_id, desc_json)
              in
              
              Lwt.return_ok ()
            in
            
            let* entity_result = Infra.Database.Pool.use db_operation in
            match entity_result with
            | Error e ->
                Stdio.eprintf "Failed to create entity for second area: %s\n" (Error.to_string_hum e);
                Lwt.return_unit
            | Ok () ->
                (* Add the components to our ECS storage *)
                let* () = Ecs.AreaStorage.set entity_id area_comp in
                let* () = Ecs.DescriptionStorage.set entity_id desc_comp in
                
                Stdio.printf "Successfully initialized second area in ECS\n";
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
          Stdio.eprintf "Failed to create exit entity: %s\n" (Error.to_string_hum e);
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
              Stdio.eprintf "Failed to create reciprocal exit entity: %s\n" (Error.to_string_hum e);
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
                    "INSERT OR IGNORE INTO entities (id) VALUES (?)")
                  exit_entity_id_str
                in
                let* _ = Db.exec 
                  (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
                    "INSERT OR IGNORE INTO entities (id) VALUES (?)")
                  recip_exit_entity_id_str
                in
                
                (* Insert exit data *)
                let exit_json = exit_comp |> [%to_yojson: Components.ExitComponent.t] |> Yojson.Safe.to_string in
                let* _ = Db.exec 
                  (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                    "INSERT OR REPLACE INTO exits (entity_id, data) VALUES (?, ?)")
                  (exit_entity_id_str, exit_json)
                in
                
                let recip_exit_json = recip_exit_comp |> [%to_yojson: Components.ExitComponent.t] |> Yojson.Safe.to_string in
                let* _ = Db.exec 
                  (Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit)
                    "INSERT OR REPLACE INTO exits (entity_id, data) VALUES (?, ?)")
                  (recip_exit_entity_id_str, recip_exit_json)
                in
                
                Lwt.return_ok ()
              in
              
              let* db_result = Infra.Database.Pool.use db_operation in
              match db_result with
              | Error e ->
                  Stdio.eprintf "Failed to create exits in database: %s\n" (Error.to_string_hum e);
                  Lwt.return_unit
              | Ok () ->
                  (* Add to ECS storage *)
                  let* () = Ecs.ExitStorage.set exit_entity_id exit_comp in
                  let* () = Ecs.ExitStorage.set recip_exit_entity_id recip_exit_comp in
                  
                  Stdio.printf "Successfully created area connection\n";
                  Lwt.return_unit

  let priority = 10  (* Run this early in the startup process *)

  (* Run initialization once at startup *)
  let initialize_starting_area_once () = 
    Lwt.async (fun () ->
      let* () = Lwt_io.printl "Initializing starting area" in
      let* () = initialize_starting_area () in
      let* () = Lwt_io.printl "Initializing second area" in
      let* () = initialize_second_area () in
      let* () = Lwt_io.printl "Creating area connection" in
      create_area_connection ())

  (* Execute function no longer performs initialization *)
  let execute () = Lwt.return_unit
end 