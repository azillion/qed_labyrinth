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

