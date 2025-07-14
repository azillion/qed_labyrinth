open Base

(* Simple test to verify seeding system loads areas into ECS *)
let test_seeding_ecs_loading () =
  let open Lwt.Syntax in
  
  (* Initialize database connection *)
  let config = Infra.Config.Database.from_env () in
  let* db_result = Infra.Database.Pool.connect config in
  match db_result with
  | Error e ->
      Stdio.eprintf "Failed to connect to database: %s\n" (Base.Error.to_string_hum e);
      Lwt.return_unit
  | Ok () ->
      (* Initialize Redis connection *)
      let redis_host = Stdlib.Sys.getenv_opt "REDIS_HOST" |> Option.value ~default:"127.0.0.1" in
      let redis_port = 
        match Stdlib.Sys.getenv_opt "REDIS_PORT" with
        | None -> 6379
        | Some port_str -> 
            try Int.of_string port_str with _ -> 6379 
      in
      let* redis = Redis_lwt.Client.connect { host = redis_host; port = redis_port } in
      
      (* Initialize ECS *)
      let* init_result = Qed_domain.Ecs.World.init redis in
      match init_result with
      | Error e ->
          Stdio.eprintf "Failed to initialize ECS: %s\n" (Base.Error.to_string_hum e);
          Lwt.return_unit
      | Ok () ->
          (* Manually load the pre-seeded starting area into ECS *)
          let starting_area_id = "00000000-0000-0000-0000-000000000000" in
          let* _ = Qed_domain.Area_loading_system.handle_load_area starting_area_id in
          (* Verify components are present *)
          match Uuidm.of_string starting_area_id with
          | None ->
              Stdio.eprintf "Invalid starting area ID\n";
              Lwt.return_unit
          | Some entity_id ->
              let* area_opt = Qed_domain.Ecs.AreaStorage.get entity_id in
              let* desc_opt = Qed_domain.Ecs.DescriptionStorage.get entity_id in
                  
                  match (area_opt, desc_opt) with
                  | (Some area, Some desc) ->
                      Stdio.printf "✓ Starting area loaded in ECS:\n";
                      Stdio.printf "  Name: %s\n" desc.Qed_domain.Components.DescriptionComponent.name;
                      Stdio.printf "  Description: %s\n" (Option.value desc.Qed_domain.Components.DescriptionComponent.description ~default:"No description");
                      Stdio.printf "  Coordinates: (%d, %d, %d)\n" area.Qed_domain.Components.AreaComponent.x area.Qed_domain.Components.AreaComponent.y area.Qed_domain.Components.AreaComponent.z;
                      Lwt.return_unit
                  | (Some _, None) ->
                      Stdio.eprintf "✗ Area component found but description missing\n";
                      Lwt.return_unit
                  | (None, Some _) ->
                      Stdio.eprintf "✗ Description component found but area missing\n";
                      Lwt.return_unit
                  | (None, None) ->
                      Stdio.eprintf "✗ Neither area nor description components found in ECS\n";
                      Lwt.return_unit

let () =
  Lwt_main.run (test_seeding_ecs_loading ()) 