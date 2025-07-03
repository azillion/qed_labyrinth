open Base

module System = struct
  let initialize () =
    let starting_area_id_str = "00000000-0000-0000-0000-000000000000" in
    let grove_id_str = "11111111-1111-1111-1111-111111111111" in
    let key_id_str = "22222222-2222-2222-2222-222222222222" in

    let starting_area_id = Uuidm.of_string starting_area_id_str |> Option.value_exn in
    let grove_id = Uuidm.of_string grove_id_str |> Option.value_exn in
    let _key_id = Uuidm.of_string key_id_str |> Option.value_exn in

    (* Ensure entities exist in ECS *)
    let () = Ecs.Entity.register starting_area_id in
    let () = Ecs.Entity.register grove_id in

    (* Define Components *)
    let meadow_area = { Components.AreaComponent.entity_id = starting_area_id_str; x = 0; y = 0; z = 0; elevation = Some 0.0; temperature = Some 0.2; moisture = Some 0.3 } in
    let meadow_desc = { Components.DescriptionComponent.entity_id = starting_area_id_str; name = "The Ancient Oak Meadow"; description = Some "An ancient oak dominates a grassy hillside." } in

    let grove_area = { Components.AreaComponent.entity_id = grove_id_str; x = 0; y = 1; z = 0; elevation = Some 0.1; temperature = Some 0.1; moisture = Some 0.4 } in
    let grove_desc = { Components.DescriptionComponent.entity_id = grove_id_str; name = "The Whispering Grove"; description = Some "A dense grove of ancient trees stands before you." } in

    let random_state = Stdlib.Random.State.make_self_init () in
    let exit_to_grove = { Components.ExitComponent.entity_id = Uuidm.to_string (Uuidm.v4_gen random_state ()) ; from_area_id = starting_area_id_str; to_area_id = grove_id_str; direction = North; description = None; hidden = false; locked = false } in
    let exit_to_meadow = { Components.ExitComponent.entity_id = Uuidm.to_string (Uuidm.v4_gen random_state ()); from_area_id = grove_id_str; to_area_id = starting_area_id_str; direction = South; description = None; hidden = false; locked = false } in
    
    (* Register exit entities in ECS so their components can be stored *)
    let exit_to_grove_id = Uuidm.of_string exit_to_grove.entity_id |> Option.value_exn in
    let exit_to_meadow_id = Uuidm.of_string exit_to_meadow.entity_id |> Option.value_exn in
    let () = Ecs.Entity.register exit_to_grove_id in
    let () = Ecs.Entity.register exit_to_meadow_id in

    (* Since we don't have these components yet, we'll skip the key for now *)
    (* let key_item = { Components.ItemComponent.entity_id = key_id_str } in *)
    (* let key_desc = { Components.DescriptionComponent.entity_id = key_id_str; name = "rusty key"; description = Some "It is an old, rusty key." } in *)
    (* let key_loc = { Components.LocationComponent.entity_id = key_id_str; area_id = starting_area_id_str } in *)

    (* Set Components in ECS *)
    let%lwt () = Ecs.AreaStorage.set starting_area_id meadow_area in
    let%lwt () = Ecs.DescriptionStorage.set starting_area_id meadow_desc in
    let%lwt () = Ecs.AreaStorage.set grove_id grove_area in
    let%lwt () = Ecs.DescriptionStorage.set grove_id grove_desc in
    let%lwt () = Ecs.ExitStorage.set (Uuidm.of_string exit_to_grove.entity_id |> Option.value_exn) exit_to_grove in
    let%lwt () = Ecs.ExitStorage.set (Uuidm.of_string exit_to_meadow.entity_id |> Option.value_exn) exit_to_meadow in

    Lwt.return ()

  let execute () =
    let%lwt all_areas = Ecs.AreaStorage.all () in
    if List.is_empty all_areas then
      initialize ()
    else
      Lwt.return ()
end