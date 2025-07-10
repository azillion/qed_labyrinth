open Lwt.Syntax
open Base

module Starting_area_initialization_system = struct
  let initialize_all_areas_and_exits () =
    let starting_area_id = "00000000-0000-0000-0000-000000000000" in
    let second_area_id = "11111111-1111-1111-1111-111111111111" in
    
    (* Single database operation to create both areas and exits atomically *)
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let open Lwt_result.Syntax in
      let* () = Db.start () in
      
      (* Insert entities first to satisfy foreign key constraints *)
      let* _ = Db.exec 
        (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
          "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING")
        starting_area_id
      in
      let* _ = Db.exec 
        (Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit)
          "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING")
        second_area_id
      in

      (* Insert starting area into areas table *)
      let* _ = Db.exec 
        (Caqti_request.Infix.(Caqti_type.(t6 string string string int int int) ->. Caqti_type.unit)
          "INSERT INTO areas (id, name, description, x, y, z) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING")
        (starting_area_id, "The Ancient Oak Meadow", 
         "An ancient oak dominates the hillside, its twisted trunk rising from the earth in massive coils. The tree's vast canopy spreads across the sky, its leaves catching rays of sunlight that pierce through gathering storm clouds above.\nThe meadow blooms with blue cornflowers and crimson poppies dotting the emerald grass.",
         0, 0, 0)
      in

      (* Insert second area into areas table *)
      let* _ = Db.exec 
        (Caqti_request.Infix.(Caqti_type.(t6 string string string int int int) ->. Caqti_type.unit)
          "INSERT INTO areas (id, name, description, x, y, z) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING")
        (second_area_id, "The Whispering Grove", 
         "A dense grove of ancient trees stands before you, their branches intertwined like the fingers of old friends. The air is thick with the scent of pine and earth, and a gentle breeze carries whispers through the leaves. Sunlight filters through the canopy in golden shafts, illuminating patches of moss-covered ground where small flowers bloom in the shadows.",
         0, 1, 0)
      in

      (* Check if exits already exist *)
      let* existing_north_exit = Db.find_opt 
        (Caqti_request.Infix.(Caqti_type.(t2 string string) ->? Caqti_type.string)
          "SELECT id FROM exits WHERE from_area_id = ? AND direction = ?")
        (starting_area_id, "north")
      in

      match existing_north_exit with
      | Some _ -> 
          (* Exits already exist, just commit *)
          let* () = Db.commit () in
          Lwt_result.return ()
      | None ->
          (* Create exits *)
          let north_exit_id = Uuidm.to_string (Uuidm.v4_gen (Stdlib.Random.State.make_self_init ()) ()) in
          let south_exit_id = Uuidm.to_string (Uuidm.v4_gen (Stdlib.Random.State.make_self_init ()) ()) in
          
          (* Insert north exit *)
          let* _ = Db.exec 
            (Caqti_request.Infix.(Caqti_type.(t4 string string string string) ->. Caqti_type.unit)
              "INSERT INTO exits (id, from_area_id, to_area_id, direction) VALUES (?, ?, ?, ?)")
            (north_exit_id, starting_area_id, second_area_id, "north")
          in

          (* Insert south exit *)
          let* _ = Db.exec 
            (Caqti_request.Infix.(Caqti_type.(t4 string string string string) ->. Caqti_type.unit)
              "INSERT INTO exits (id, from_area_id, to_area_id, direction) VALUES (?, ?, ?, ?)")
            (south_exit_id, second_area_id, starting_area_id, "south")
          in

          let* () = Db.commit () in
          Lwt_result.return ()
    in

    let* db_result = Infra.Database.Pool.use db_operation in
    match db_result with
    | Error e ->
        let* () = Lwt_io.printl (Printf.sprintf "Failed to initialize areas and exits: %s" (Error.to_string_hum e)) in
        Lwt.return_unit
    | Ok () ->
        (* Now add areas to ECS if they don't already exist *)
        let* () = match Uuidm.of_string starting_area_id with
          | None -> Lwt.return_unit
          | Some entity_id ->
              let* existing_area = Ecs.AreaStorage.get entity_id in
              match existing_area with
              | Some _ -> Lwt.return_unit
              | None ->
                  let area_comp = Components.AreaComponent.{
                    entity_id = starting_area_id;
                    x = 0;
                    y = 0;
                    z = 0;
                    elevation = Some 0.0;
                    temperature = Some 0.0;
                    moisture = Some 0.0;
                  } in
                  let desc_comp = Components.DescriptionComponent.{
                    entity_id = starting_area_id;
                    name = "The Ancient Oak Meadow";
                    description = Some "An ancient oak dominates the hillside, its twisted trunk rising from the earth in massive coils. The tree's vast canopy spreads across the sky, its leaves catching rays of sunlight that pierce through gathering storm clouds above.\nThe meadow blooms with blue cornflowers and crimson poppies dotting the emerald grass.";
                  } in
                  let* _ = Ecs.Entity.ensure_exists entity_id in
                  let* () = Ecs.AreaStorage.set entity_id area_comp in
                  let* () = Ecs.DescriptionStorage.set entity_id desc_comp in
                  Lwt.return_unit
        in

        let* () = match Uuidm.of_string second_area_id with
          | None -> Lwt.return_unit
          | Some entity_id ->
              let* existing_area = Ecs.AreaStorage.get entity_id in
              match existing_area with
              | Some _ -> Lwt.return_unit
              | None ->
                  let area_comp = Components.AreaComponent.{
                    entity_id = second_area_id;
                    x = 0;
                    y = 1;
                    z = 0;
                    elevation = Some 0.0;
                    temperature = Some 0.0;
                    moisture = Some 0.0;
                  } in
                  let desc_comp = Components.DescriptionComponent.{
                    entity_id = second_area_id;
                    name = "The Whispering Grove";
                    description = Some "A dense grove of ancient trees stands before you, their branches intertwined like the fingers of old friends. The air is thick with the scent of pine and earth, and a gentle breeze carries whispers through the leaves. Sunlight filters through the canopy in golden shafts, illuminating patches of moss-covered ground where small flowers bloom in the shadows.";
                  } in
                  let* _ = Ecs.Entity.ensure_exists entity_id in
                  let* () = Ecs.AreaStorage.set entity_id area_comp in
                  let* () = Ecs.DescriptionStorage.set entity_id desc_comp in
                  Lwt.return_unit
        in

        let* () = Lwt_io.printl "Successfully initialized all areas and exits" in
        Lwt.return_unit

  let priority = 10  (* Run this early in the startup process *)

  (* Run initialization once at startup - now with proper transaction handling *)
  let initialize_starting_area_once () =
    let open Lwt.Syntax in
    let* () = Lwt_io.printl "Initializing all areas and exits" in
    initialize_all_areas_and_exits ()

  (* Execute function no longer performs initialization *)
  let execute () = Lwt.return_unit
end 