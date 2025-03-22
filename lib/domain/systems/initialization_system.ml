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

  let priority = 10  (* Run this early in the startup process *)

  (* Run initialization once at startup *)
  let initialize_starting_area_once () = 
    Lwt.async (fun () ->
      let* () = Lwt_io.printl "Initializing starting area" in
      initialize_starting_area ())

  (* Execute function no longer performs initialization *)
  let execute () = Lwt.return_unit
end 