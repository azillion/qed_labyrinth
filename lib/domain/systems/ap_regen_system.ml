open Base
open Lwt_result.Syntax
open Error_utils

(* This module implements passive Action Point regeneration for characters. *)
module AP_regen_system = struct
  module APRegenLogic : System.Tickable = struct
    let name = "ap-regen"

    (* Track the last time each entity received AP regeneration. Using entity_id string keys
       because they are easy to hash/comparison with Base.Hashtbl. *)
    let last_tick_times : (string, float) Hashtbl.t = Hashtbl.create (module String)

    (* How often to regenerate (in seconds) and how much to add each tick *)
    let regen_interval = 5.0
    let regen_amount   = 1

    let execute _state =
      let open Lwt_result.Syntax in
      let now = Unix.gettimeofday () in

      (* Fetch all ActionPoints components currently loaded in ECS *)
      let* all_ap_components = wrap_val (Ecs.ActionPointsStorage.all ()) in

      let process (entity_id, (ap_comp : Components.ActionPointsComponent.t)) =
        let id_str = Uuidm.to_string entity_id in
        let last_time = Hashtbl.find last_tick_times id_str |> Option.value ~default:0.0 in
        if Float.(now -. last_time >= regen_interval) then
          if ap_comp.current < ap_comp.max then (
            let new_ap = Int.min ap_comp.max (ap_comp.current + regen_amount) in
            let updated = { ap_comp with current = new_ap } in
            let* () = wrap_ok (Ecs.ActionPointsStorage.set entity_id updated) in
            Hashtbl.set last_tick_times ~key:id_str ~data:now;
            Lwt_result.return ()
          ) else (
            Hashtbl.set last_tick_times ~key:id_str ~data:now;
            Lwt_result.return ())
        else Lwt_result.return ()
      in

      let rec loop lst =
        match lst with
        | [] -> Lwt_result.return ()
        | hd :: tl ->
            let* () = process hd in
            loop tl
      in

      let* () = loop all_ap_components in
      Lwt_result.return ()
  end

  module APRegen = System.MakeTickable (APRegenLogic)
end

(* Expose the AP_regen_system module and its APRegen submodule *)
include AP_regen_system 