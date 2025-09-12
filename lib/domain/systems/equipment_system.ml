open Base
open Qed_error

(* --- Equip System --- *)
module EquipLogic : System.S with type event = Event.equip_payload = struct
  let name = "Equip"
  type event = Event.equip_payload
  let event_type = function Event.Equip p -> Some p | _ -> None

  let execute state _trace_id ({ user_id; character_id=_; item_entity_id } : event) =
    let open Lwt_result.Syntax in
    let* character = Character_actions.find_active ~state ~user_id |> Lwt.map (Result.map_error ~f:(fun s -> LogicError s)) in
    let* item = Item_actions.find ~item_entity_id_str:item_entity_id |> Lwt.map (Result.map_error ~f:(fun s -> LogicError s)) in

    match%lwt Character_actions.equip ~state ~character ~item with
    | Ok () ->
        let* () = Character_actions.refresh_client_ui ~state ~character in
        Lwt_result.return ()
    | Error reason ->
        let* () = Character_actions.send_message ~state ~character ~message:reason in
        Lwt_result.return ()
end
module Equip = System.Make (EquipLogic)

(* --- Unequip System --- *)
module UnequipLogic : System.S with type event = Event.unequip_payload = struct
  let name = "Unequip"
  type event = Event.unequip_payload
  let event_type = function Event.Unequip p -> Some p | _ -> None

  let execute state _trace_id ({ user_id; character_id=_; slot } : event) =
    let open Lwt_result.Syntax in
    let* character = Character_actions.find_active ~state ~user_id |> Lwt.map (Result.map_error ~f:(fun s -> LogicError s)) in

    match%lwt Character_actions.unequip ~state ~character ~slot with
    | Ok () ->
        let* () = Character_actions.refresh_client_ui ~state ~character in
        Lwt_result.return ()
    | Error reason ->
        let* () = Character_actions.send_message ~state ~character ~message:reason in
        Lwt_result.return ()
end
module Unequip = System.Make (UnequipLogic) 