type t = { filename : string; events : Event.t list }

let create filename = { filename; events = [] }

let load filename =
  try
    let json = Yojson.Safe.from_file filename in
    let events =
      match json with
      | `List events ->
          List.filter_map
            (fun event ->
              match event with
              | `List [ event_type; event_data ] ->
                  (match Event.of_yojson (`List [ event_type; event_data ]) with
                   | Ok e -> Some e
                   | Error _ -> None)
              | _ -> 
                  (match Event.of_yojson event with
                   | Ok e -> Some e
                   | Error _ -> None))
            events
      | _ -> failwith "Expected JSON array of events"
    in
    { filename; events }
  with
  | Sys_error _ -> { filename; events = [] }
  | Yojson.Safe.Util.Type_error (msg, _) ->
      Printf.printf "Error parsing events: %s\n" msg;
      { filename; events = [] }

let append store event =
  let events = event :: store.events in
  let json = `List (List.map Event.to_yojson events) in
  Yojson.Safe.to_file store.filename json;
  { store with events }

let get_events store = List.rev store.events
