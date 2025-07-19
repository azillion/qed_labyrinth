open Base
open Qed_error

module LoadAreaLogic : System.S with type event = Event.load_area_into_ecs_payload = struct
  let name = "LoadAreaIntoECS"
  type event = Event.load_area_into_ecs_payload
  let event_type = function Event.LoadAreaIntoECS e -> Some e | _ -> None

  let execute _state _trace_id ({ area_id } : event) =
    let open Lwt_result.Syntax in
    match Uuidm.of_string area_id with
    | None -> Lwt_result.fail InvalidAreaId
    | Some entity_id ->
      let* () = Ecs.Entity.ensure_exists entity_id |> Lwt.map (Result.map_error ~f:(fun e -> DatabaseError (Error.to_string_hum e))) in
      Lwt_result.return ()
end
module LoadArea = System.Make(LoadAreaLogic) 