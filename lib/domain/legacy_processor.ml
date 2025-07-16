open Base
open Error_utils

let process_event (state : State.t) (_trace_id : string option) (event : Event.t)
    : (unit, Qed_error.t) Result.t Lwt.t =
  match event with
  | Event.SendMovementFailed { user_id; reason } ->
      let open Lwt_result.Syntax in
      let* () = Publisher.publish_system_message_to_user state user_id reason in
      Lwt_result.return ()
  | Event.SendInventory { user_id; items } ->
      let pb_items = List.map items ~f:(fun (item_id, name_, description_, quantity_) ->
        Schemas_generated.Output.{ id = item_id; name = name_; description = description_; quantity = Int32.of_int_exn quantity_ }) in
      let inventory_list_msg = Schemas_generated.Output.{ items = pb_items } in
      let output_event = Schemas_generated.Output.{ target_user_ids = [user_id]; payload = Inventory_list inventory_list_msg; trace_id = "" } in
      Publisher.publish_event state output_event
  | Event.ActionFailed { user_id; reason } ->
      Publisher.publish_system_message_to_user state user_id reason
  | _ -> Lwt.return_ok () 