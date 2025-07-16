open Base

module Metrics = struct
  type metric =
    | Counter of int ref
    | Gauge of float ref
    | Summary of { sum: float ref; count: int ref }

  let store : (string, metric) Hashtbl.t = Hashtbl.create (module String)
  let mutex = Lwt_mutex.create ()

  let get_or_create name ~default =
    match Hashtbl.find store name with
    | Some m -> m
    | None ->
        let m = default () in
        Hashtbl.set store ~key:name ~data:m;
        m

  let inc name =
    Lwt.async (fun () ->
      Lwt_mutex.with_lock mutex (fun () ->
        let metric = get_or_create name ~default:(fun () -> Counter (ref 0)) in
        match metric with
        | Counter r -> Int.incr r; Lwt.return_unit
        | _ -> Lwt.return_unit (* Type mismatch, ignore *)
      )
    )

  let set_gauge name value =
     Lwt.async (fun () ->
      Lwt_mutex.with_lock mutex (fun () ->
        let metric = get_or_create name ~default:(fun () -> Gauge (ref 0.0)) in
        match metric with
        | Gauge r -> r := value; Lwt.return_unit
        | _ -> Lwt.return_unit
      )
    )

  let observe_duration name seconds =
    Lwt.async (fun () ->
      Lwt_mutex.with_lock mutex (fun () ->
        let metric = get_or_create name ~default:(fun () -> Summary { sum = ref 0.0; count = ref 0 }) in
        match metric with
        | Summary s ->
            s.sum := !(s.sum) +. seconds;
            Int.incr s.count;
            Lwt.return_unit
        | _ -> Lwt.return_unit
      )
    )

  let to_yojson () =
    let kv_list = Hashtbl.to_alist store |> List.map ~f:(fun (k, v) ->
      let json_v = match v with
        | Counter r -> `Assoc [("type", `String "counter"); ("value", `Int !r)]
        | Gauge r -> `Assoc [("type", `String "gauge"); ("value", `Float !r)]
        | Summary s ->
            let avg = if !(s.count) > 0 then !(s.sum) /. (Float.of_int !(s.count)) else 0.0 in
            `Assoc [
              ("type", `String "summary");
              ("sum", `Float !(s.sum));
              ("count", `Int !(s.count));
              ("avg", `Float avg)
            ]
      in
      (k, json_v)
    ) in
    `Assoc kv_list
end

module Log = struct
  type level = Debug | Info | Warn | Error
  let string_of_level = function
    | Debug -> "DEBUG" | Info -> "INFO" | Warn -> "WARN" | Error -> "ERROR"

  let log level msg data =
    let now = Ptime_clock.now () |> Ptime.to_rfc3339 in
    let data_json = List.map data ~f:(fun (k, v) -> (k, `String v)) in
    let json = `Assoc ([
        ("timestamp", `String now);
        ("level", `String (string_of_level level));
        ("message", `String msg);
      ] @ data_json)
    in
    Lwt_io.printl (Yojson.Safe.to_string json)

  let debug msg ?(data=[]) () = log Debug msg data
  let info msg ?(data=[]) () = log Info msg data
  let warn msg ?(data=[]) () = log Warn msg data
  let error msg ?(data=[]) () = log Error msg data
end 