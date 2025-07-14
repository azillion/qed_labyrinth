open Base

(* Helper to convert a direction string from world.json into the ExitComponent.direction type *)
let exit_direction_of_string s = Components.ExitComponent.string_to_direction s

let rec seed_item_definitions defs =
  let open Lwt_result.Syntax in
  match defs with
  | [] -> Lwt_result.return ()
  | idef :: rest ->
      let Item_definition.{ name; description; item_type; slot; weight; is_stackable; properties; _ } = idef in
      let* _created =
        Item_definition.create
          ~name
          ~description
          ~item_type
          ~slot
          ~weight
          ~is_stackable
          ?properties
          ()
      in
      seed_item_definitions rest

let rec seed_areas areas =
  let open Lwt_result.Syntax in
  match areas with
  | [] -> Lwt_result.return ()
  | (id, name, description, x, y, z) :: rest ->
      let* _created = Area.create ~id ~name ~description ~x ~y ~z () in
      (* Also load the area into ECS immediately after creation *)
      let* () = Area_loading_system.handle_load_area id in
      seed_areas rest

let rec seed_exits exits =
  let open Lwt_result.Syntax in
  match exits with
  | [] -> Lwt_result.return ()
  | (from_id, to_id, dir_str) :: rest ->
      (match exit_direction_of_string dir_str with
      | None -> Lwt_result.fail (Qed_error.LogicError "Invalid direction in world.json")
      | Some direction ->
          let* _ = Exit.create ~from_area_id:from_id ~to_area_id:to_id ~direction in
          seed_exits rest)

let seed_world_if_needed () =
  let open Lwt_result.Syntax in
  let* existing_areas = Area.get_all_areas () in
  match existing_areas with
  | _ :: _ -> Lwt_result.return ()
  | [] ->
      let world_data =
        match Seeding.from_file "world.json" with
        | Ok w -> w
        | Error msg -> failwith msg
      in
      let* () = seed_item_definitions (Seeding.get_item_definitions world_data) in
      let* () = seed_areas (Seeding.get_areas world_data) in
      let* () = seed_exits (Seeding.get_exits world_data) in
      Lwt_result.return () 