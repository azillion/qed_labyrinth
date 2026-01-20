open Base
open Error_utils

(* --- Area Query System --- *)
module AreaQueryLogic : System.S with type event = Event.area_query_payload = struct
  let name = "AreaQuery"
  type event = Event.area_query_payload
  let event_type = function Event.AreaQuery e -> Some e | _ -> None

  (* Helper to find all item entities in the specified area and map them to Types.area_item *)
  let find_items_in_area area_id =
    let%lwt item_positions = Ecs.ItemPositionStorage.all () in
    let entities_in_area =
      List.filter item_positions ~f:(fun (_, pos) -> String.equal pos.area_id area_id)
      |> List.map ~f:fst
    in
    let%lwt item_comps =
      Lwt_list.filter_map_s (fun eid ->
        let%lwt comp_opt = Ecs.ItemStorage.get eid in
        Lwt.return (Option.map comp_opt ~f:(fun comp -> (eid, comp)))
      ) entities_in_area
    in
    let definition_ids =
      List.map item_comps ~f:(fun (_, comp) -> comp.item_definition_id)
      |> List.dedup_and_sort ~compare:String.compare
    in
    let%lwt names_result = Item_definition.find_names_by_ids definition_ids in
    match names_result with
    | Error _ -> Lwt.return []
    | Ok pairs ->
        let name_map = Map.of_alist_exn (module String) pairs in
        Lwt.return (
          List.filter_map item_comps ~f:(fun (eid, comp) ->
            Map.find name_map comp.item_definition_id
            |> Option.map ~f:(fun name -> Types.{ id = Uuidm.to_string eid; name }))
        )

  let execute state trace_id ({ user_id; area_id } : event) =
    let open Lwt_result.Syntax in
    match%lwt Area.find_by_id area_id with
    | Error e -> Lwt.return_error e
    | Ok area_model ->
        let* exits = Exit.find_by_area ~area_id in
        let exit_types =
          List.map exits ~f:(fun exit ->
            { Types.direction = Components.ExitComponent.direction_to_string exit.direction })
        in
        let* items_here = wrap_val (find_items_in_area area_id) in
        let area_info : Types.area = {
          id = area_id;
          name = area_model.name;
          description = area_model.description;
          coordinate = Some { x = area_model.x; y = area_model.y; z = area_model.z };
          exits = exit_types;
          items = items_here;
          elevation = area_model.elevation;
          temperature = area_model.temperature;
          moisture = area_model.moisture;
        } in
        let* () = wrap_ok (State.enqueue ?trace_id state (Event.AreaQueryResult { user_id; area = area_info })) in
        let* () = wrap_ok (State.enqueue ?trace_id state (Event.RequestChatHistory { user_id; area_id })) in
        Lwt_result.return ()
end
module AreaQuery = System.Make(AreaQueryLogic)

(* --- Area Query Result System --- *)
module AreaQueryResultLogic : System.S with type event = Event.area_query_result_payload = struct
  let name = "AreaQueryResult"
  type event = Event.area_query_result_payload
  let event_type = function Event.AreaQueryResult e -> Some e | _ -> None

  let execute state trace_id ({ user_id; area } : event) =
    let open Lwt_result.Syntax in
    let exits_pb =
      List.map area.exits ~f:(fun exit -> Schemas_generated.Output.{ direction = exit.direction })
    in
    let items_pb : Schemas_generated.Output.area_item list =
      List.map area.items ~f:(fun item ->
        (Schemas_generated.Output.{ id = item.id; name = item.name } : Schemas_generated.Output.area_item))
    in
    let area_update = Schemas_generated.Output.{
      area_id = area.id;
      name = area.name;
      description = area.description;
      exits = exits_pb;
      items = items_pb;
    } in
    let output_event = Schemas_generated.Output.{
      target_user_ids = [ user_id ];
      payload = Area_update area_update;
      trace_id = "";
    } in
    let* () = Publisher.publish_event state ?trace_id output_event in
    Lwt_result.return ()
end
module AreaQueryResult = System.Make(AreaQueryResultLogic) 