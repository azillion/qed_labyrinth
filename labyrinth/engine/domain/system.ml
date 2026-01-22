open Base
open Lwt.Syntax
open Infra

(* ------------------------------------------------------------------ *)
(* Module types                                                        *)
(* ------------------------------------------------------------------ *)

module type S = sig
  val name : string
  type event
  val event_type : Event.t -> event option
  val execute : State.t -> string option -> event -> (unit, Qed_error.t) Result.t Lwt.t
end

module type Tickable = sig
  val name : string
  val execute : State.t -> (unit, Qed_error.t) Result.t Lwt.t
end

(* ------------------------------------------------------------------ *)
(* Event-based system wrapper                                          *)
(* ------------------------------------------------------------------ *)

module Make (Sys : S) = struct
  let handle (state : State.t) (trace_id : string option) (event_opt : Event.t option)
      : (unit, Qed_error.t) Result.t Lwt.t =
    match event_opt with
    | None -> Lwt.return_ok ()  (* Should not be invoked without an event *)
    | Some event -> (
        match Sys.event_type event with
        | None -> Lwt.return_ok ()  (* Event not handled by this system *)
        | Some specific_event ->
            let start_time = Unix.gettimeofday () in
            let trace_id_str = Option.value trace_id ~default:"N/A" in
            let data = [ ("system", Sys.name); ("trace_id", trace_id_str) ] in

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
                let* () =
                  Monitoring.Log.error "System execution failed"
                    ~data:([ ("error", error_str) ] @ data) ()
                in
                Lwt.return_error e))
end

(* ------------------------------------------------------------------ *)
(* Tick-based system wrapper                                           *)
(* ------------------------------------------------------------------ *)

module MakeTickable (Sys : Tickable) = struct
  let handle (state : State.t) (_trace_id : string option) (_event_opt : Event.t option)
      : (unit, Qed_error.t) Result.t Lwt.t =
    let start_time = Unix.gettimeofday () in
    let data = [ ("system", Sys.name); ("trigger", "OnTick") ] in

    (* let* () = Monitoring.Log.debug "Executing tickable system" ~data () in *)
    let%lwt result = Sys.execute state in
    let duration = Unix.gettimeofday () -. start_time in
    Monitoring.Metrics.observe_duration (Sys.name ^ "_duration_seconds") duration;

    match result with
    | Ok () ->
        Monitoring.Metrics.inc (Sys.name ^ "_success_total");
        Lwt.return_ok ()
    | Error e ->
        let error_str = Qed_error.to_string e in
        Monitoring.Metrics.inc (Sys.name ^ "_error_total");
        let* () =
          Monitoring.Log.error "Tickable system execution failed"
            ~data:([ ("error", error_str) ] @ data) ()
        in
        Lwt.return_error e
end