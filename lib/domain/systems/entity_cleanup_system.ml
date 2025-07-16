open Infra

module EntityCleanupLogic : System.Tickable = struct
  let name = "entity-cleanup"

  let execute _state =
    (* In a real implementation, this would query for entities marked for deletion
       and remove their components from the ECS. For now, it just logs. *)
    let open Lwt_result.Syntax in
    let* () = Monitoring.Log.debug "Running entity cleanup" ~data:[] () |> Error_utils.wrap_ok in
    Lwt.return_ok ()
end

module EntityCleanup = System.MakeTickable(EntityCleanupLogic) 