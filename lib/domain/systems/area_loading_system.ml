open Base
open Qed_error

let handle_load_area (area_id : string) : (unit, Qed_error.t) Result.t Lwt.t =
  let open Lwt_result.Syntax in
  
  (* 1. Check if area is already in ECS to prevent duplicate work *)
  let* entity_id_opt = Uuidm.of_string area_id |> Lwt_result.return in
  match entity_id_opt with
  | None -> Lwt_result.fail (InvalidAreaId)
  | Some entity_id ->
      let* existing_area_opt = Error_utils.wrap_val (Ecs.AreaStorage.get entity_id) in
      if Option.is_some existing_area_opt then (
        (* Area already loaded, but ensure description is set *)
        let* area_model = Area.find_by_id area_id in
        let desc_comp = Components.DescriptionComponent.{
          entity_id = area_model.id;
          name = area_model.name;
          description = Some area_model.description;
        } in
        let* () = Error_utils.wrap_ok (Ecs.DescriptionStorage.set entity_id desc_comp) in
        Lwt_result.return ()
      ) else (
        (* 2. Area not in ECS, load from relational DB *)
        let* area_model = Area.find_by_id area_id in
        (* 3. Ensure entity exists in the ECS registry *)
        let* () = Ecs.Entity.ensure_exists entity_id |> Lwt.map (Result.map_error ~f:(fun e -> DatabaseError (Error.to_string_hum e))) in
        (* 4. Create and set AreaComponent *)
        let area_comp = Components.AreaComponent.{ 
          entity_id = area_model.id;
          x = area_model.x;
          y = area_model.y;
          z = area_model.z;
          elevation = area_model.elevation;
          temperature = area_model.temperature;
          moisture = area_model.moisture;
        } in
        let* () = Error_utils.wrap_ok (Ecs.AreaStorage.set entity_id area_comp) in
        (* 5. Create and set DescriptionComponent *)
        let desc_comp = Components.DescriptionComponent.{ 
          entity_id = area_model.id;
          name = area_model.name; 
          description = Some area_model.description 
        } in
        let* () = Error_utils.wrap_ok (Ecs.DescriptionStorage.set entity_id desc_comp) in
        Lwt.return_ok ()
      ) 