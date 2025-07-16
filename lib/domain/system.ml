open Base
open Lwt.Syntax
open Infra

module type S = sig
  val name : string
  type event
  val event_type : Event.t -> event option
  val execute : State.t -> string option -> event -> (unit, Qed_error.t) Result.t Lwt.t
end

module Make (Sys : S) = struct
  let handle (state : State.t) (trace_id : string option) (event : Event.t) =
    match Sys.event_type event with
    | None ->
        (* This should not happen if the dispatcher is correct, but is a safeguard. *)
        Lwt.return_ok ()
    | Some specific_event ->
        let start_time = Unix.gettimeofday () in
        let trace_id_str = Option.value trace_id ~default:"N/A" in
        let data = [("system", Sys.name); ("trace_id", trace_id_str)] in

        let* () = Monitoring.Log.debug "Executing system" ~data () in
        let%lwt result = Sys.execute state trace_id specific_event in
        let duration = Unix.gettimeofday () -. start_time in

        Monitoring.Metrics.observe_duration (Sys.name ^ "_duration_seconds") duration;

        (match result with
        | Ok () ->
            Monitoring.Metrics.inc (Sys.name ^ "_success_total");
            let* () = Monitoring.Log.debug "System executed successfully" ~data () in
            Lwt.return_ok ()
        | Error e ->
            let error_str = Qed_error.to_string e in
            Monitoring.Metrics.inc (Sys.name ^ "_error_total");
            let* () = Monitoring.Log.error "System execution failed" ~data:([("error", error_str)] @ data) () in
            Lwt.return_error e)
end 