open Base
open Qed_error

let handle_load_area (area_id : string) : (unit, Qed_error.t) Result.t Lwt.t =
  let open Lwt_result.Syntax in
  
  (* 1. Check if area is already in ECS to prevent duplicate work *)
  let* entity_id_opt = Uuidm.of_string area_id |> Lwt_result.return in
  match entity_id_opt with
  | None -> Lwt_result.fail (InvalidAreaId)
  | Some entity_id ->
      (* TODO: This is a hack to ensure the area is tracked. We should find a better way to do this. *)
      (* Area data is now directly served from relational storage; we only ensure the entity is tracked. *)
      let* () = Ecs.Entity.ensure_exists entity_id |> Lwt.map (Result.map_error ~f:(fun e -> DatabaseError (Error.to_string_hum e))) in
      Lwt_result.return () 