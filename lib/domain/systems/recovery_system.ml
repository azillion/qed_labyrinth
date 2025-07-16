open Base
open Infra

module RecoveryLogic : System.Tickable = struct
  let name = "recovery"
  let recovery_duration = 15.0 (* seconds *)

  let execute _state =
    let open Lwt_result.Syntax in
    let now = Unix.gettimeofday () in
    let* all_unconscious = Ecs.UnconsciousStorage.all () |> Error_utils.wrap_val in

    let* () =
      Lwt_list.iter_p (fun (entity_id, (unconscious_comp : Unconscious_component.t)) ->
        if Float.(now - unconscious_comp.knockout_time >= recovery_duration) then
          (* Time to recover! *)
          let%lwt () = Ecs.UnconsciousStorage.remove entity_id in
          let%lwt health_comp_opt = Ecs.HealthStorage.get entity_id in
          let%lwt () =
            match health_comp_opt with
            | Some hc ->
                let recovered_hc = { hc with current = 1 } in
                Ecs.HealthStorage.set entity_id recovered_hc
            | None -> Lwt.return_unit (* Should not happen if they were knocked out *)
          in
          Monitoring.Log.info "Character has recovered from knockout" ~data:[("entity_id", Uuidm.to_string entity_id)] ()
        else
          Lwt.return_unit
      ) all_unconscious |> Error_utils.wrap_ok
    in
    Lwt.return_ok ()
end

module Recovery = System.MakeTickable(RecoveryLogic) 