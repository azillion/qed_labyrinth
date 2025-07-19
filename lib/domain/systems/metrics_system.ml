open Base
open Infra

module RequestMetricsLogic : System.S with type event = Event.request_admin_metrics_payload = struct
  let name = "RequestAdminMetrics"

  type event = Event.request_admin_metrics_payload

  let event_type = function
    | Event.RequestAdminMetrics e -> Some e
    | _ -> None

  let execute state trace_id (payload : event) =
    let user_id = payload.user_id in
    let open Lwt_result.Syntax in
    let metrics_json = Monitoring.Metrics.to_yojson () |> Yojson.Safe.to_string in
    let report = Schemas_generated.Output.{ json_payload = metrics_json } in
    let output_event = Schemas_generated.Output.{
      target_user_ids = [ user_id ];
      payload = Metrics_report report;
      trace_id = Option.value ~default:"" trace_id;
    } in
    let* () = Publisher.publish_event state ?trace_id output_event in
    Lwt_result.return ()
end

module RequestMetrics = System.Make (RequestMetricsLogic) 