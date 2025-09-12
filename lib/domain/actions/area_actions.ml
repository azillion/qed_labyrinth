open Base

type t = { entity_id: Uuidm.t }

let find_by_id ~area_id_str =
  let open Lwt_result.Syntax in
  match Uuidm.of_string area_id_str with
  | None -> Lwt_result.fail "Invalid area ID format."
  | Some entity_id ->
      let* _ = Area.find_by_id area_id_str |> Lwt.map (Result.map_error ~f:Qed_error.to_string) in
      Lwt_result.return { entity_id }

let get_id t = Uuidm.to_string t.entity_id

let find_exit ~area ~direction =
  let open Lwt_result.Syntax in
  let area_id_str = get_id area in
  let* exit_opt = Exit.find_by_area_and_direction ~area_id:area_id_str ~direction
    |> Lwt.map (Result.map_error ~f:Qed_error.to_string)
  in
  match exit_opt with
  | Some exit_record -> Lwt_result.return exit_record
  | None -> Lwt_result.fail "You can't go that way."


let find_item ~area ~item_id_str =
  let open Lwt_result.Syntax in
  let* item = Item_actions.find ~item_entity_id_str:item_id_str in
  let item_uuid =
    match Uuidm.of_string (Item_actions.get_id ~item) with
    | None -> None
    | Some eid -> Some eid
  in
  let* pos_comp_opt =
    match item_uuid with
    | None -> Lwt_result.fail "Invalid item ID format."
    | Some eid ->
        let%lwt pos_opt = Ecs.ItemPositionStorage.get eid in
        Lwt_result.return pos_opt
  in
  match pos_comp_opt with
  | Some pos when String.equal pos.area_id (get_id area) -> Lwt_result.return item
  | _ -> Lwt_result.fail "That item is not here."

let remove_item ~area ~item =
  let open Lwt_result.Syntax in
  let item_uuid =
    match Uuidm.of_string (Item_actions.get_id ~item) with
    | None -> None
    | Some eid -> Some eid
  in
  let* pos_comp_opt =
    match item_uuid with
    | None -> Lwt_result.fail "Invalid item ID format."
    | Some eid ->
        let%lwt pos_opt = Ecs.ItemPositionStorage.get eid in
        Lwt_result.return pos_opt
  in
  match pos_comp_opt with
  | Some pos when String.equal pos.area_id (get_id area) ->
      (match item_uuid with
      | None -> Lwt_result.fail (Qed_error.LogicError "Invalid item ID format.")
      | Some eid -> Error_utils.wrap_ok (Ecs.ItemPositionStorage.remove eid))
      |> Lwt.map (Result.map_error ~f:(fun e -> Qed_error.to_string e))
  | _ -> Lwt_result.fail "Item is not in the specified area to remove."

let add_item ~area ~item =
  match Uuidm.of_string (Item_actions.get_id ~item) with
  | None -> Lwt_result.fail "Invalid item ID format."
  | Some eid ->
      let new_pos_comp = Components.ItemPositionComponent.{
        entity_id = Item_actions.get_id ~item;
        area_id = get_id area;
      } in
      Error_utils.wrap_ok (Ecs.ItemPositionStorage.set eid new_pos_comp)
      |> Lwt.map (Result.map_error ~f:(fun e -> Qed_error.to_string e))

