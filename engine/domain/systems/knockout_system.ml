open Base
open Infra

module KnockoutLogic : System.Tickable = struct
  let name = "Knockout"

  let execute _state =
    let open Lwt_result.Syntax in
    let modified_health_entities = Ecs.HealthStorage.get_modified () in

    let* () =
      Lwt_list.iter_p (fun entity_id ->
        let%lwt health_comp_opt = Ecs.HealthStorage.get entity_id in
        match health_comp_opt with
        | Some hc when hc.current <= 0 ->
          (* Character is knocked out. Check if they are already unconscious. *)
          let%lwt is_unconscious = Ecs.UnconsciousStorage.get entity_id in
          (match is_unconscious with
          | Some _ -> Lwt.return_unit (* Already unconscious, do nothing. *)
          | None ->
            (* Apply the unconscious component and log it. *)
            let knockout_comp = Unconscious_component.{ knockout_time = Unix.gettimeofday () } in
            let%lwt () = Ecs.UnconsciousStorage.set entity_id knockout_comp in
            Monitoring.Log.info "Character has been knocked out" ~data:[("entity_id", Uuidm.to_string entity_id)] ())
        | _ -> Lwt.return_unit
      ) modified_health_entities |> Error_utils.wrap_ok
    in
    Lwt.return_ok ()
end

module Knockout = System.MakeTickable(KnockoutLogic) 