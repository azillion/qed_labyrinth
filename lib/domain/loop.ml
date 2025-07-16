open Lwt.Syntax
open Base
open Infra

module Queue = Infra.Queue

let string_of_event_type = Dispatcher.string_of_event_type

(* Helper function to convert protobuf directions to internal directions *)
let direction_of_proto (proto_direction : Schemas_generated.Input.direction) =
  match proto_direction with
  | Schemas_generated.Input.North -> Components.ExitComponent.North
  | Schemas_generated.Input.South -> Components.ExitComponent.South
  | Schemas_generated.Input.East -> Components.ExitComponent.East
  | Schemas_generated.Input.West -> Components.ExitComponent.West
  | Schemas_generated.Input.Up -> Components.ExitComponent.Up
  | Schemas_generated.Input.Down -> Components.ExitComponent.Down
  | Schemas_generated.Input.Unspecified -> failwith "Unspecified direction"

(* Main conversion function from protobuf to internal events *)
let event_of_protobuf (proto_event : Schemas_generated.Input.input_event) : (string * Event.t) option =
  let trace_id = proto_event.trace_id in
  match proto_event.payload with
  | None -> None
  | Some payload ->
      match payload with
      | Move move_cmd ->
          let direction = direction_of_proto move_cmd.direction in
          Some (trace_id, Event.Move { user_id = proto_event.user_id; direction })
      | Say say_cmd ->
          Some (trace_id, Event.Say { user_id = proto_event.user_id; content = say_cmd.content })
      | Create_character create_cmd ->
          (match Int32.to_int create_cmd.might, Int32.to_int create_cmd.finesse, Int32.to_int create_cmd.wits, Int32.to_int create_cmd.grit, Int32.to_int create_cmd.presence with
          | Some might, Some finesse, Some wits, Some grit, Some presence ->
              Some (trace_id, Event.CreateCharacter {
                user_id = proto_event.user_id;
                name = create_cmd.name;
                description = "";
                starting_area_id = "00000000-0000-0000-0000-000000000000";
                might = might;
                finesse = finesse;
                wits = wits;
                grit = grit;
                presence = presence
              })
          | _ -> None)
      | List_characters ->
          Some (trace_id, Event.CharacterListRequested { user_id = proto_event.user_id })
      | Select_character select_cmd ->
          Some (trace_id, Event.CharacterSelected { user_id = proto_event.user_id; character_id = select_cmd.character_id })
      | Take take_cmd ->
          Some (trace_id, Event.TakeItem { user_id = proto_event.user_id; character_id = take_cmd.character_id; item_entity_id = take_cmd.item_entity_id })
      | Drop drop_cmd ->
          Some (trace_id, Event.DropItem { user_id = proto_event.user_id; character_id = drop_cmd.character_id; item_entity_id = drop_cmd.item_entity_id })
      | Request_inventory inv_cmd ->
          Some (trace_id, Event.RequestInventory { user_id = proto_event.user_id; character_id = inv_cmd.character_id })

(* Redis subscriber function *)
let subscribe_to_player_commands (state : State.t) =
  let open Lwt.Syntax in
  let redis_host =
    try Stdlib.Sys.getenv "REDIS_HOST"
    with _ -> failwith "REDIS_HOST environment variable is not set"
  in
  let%lwt subscriber_conn = Redis_lwt.Client.connect { host = redis_host; port = 6379 } in
  let%lwt () = Redis_lwt.Client.subscribe subscriber_conn ["player_commands"] in
  let%lwt () = Monitoring.Log.info "Subscribed to player_commands" () in
  let reply_stream = Redis_lwt.Client.stream subscriber_conn in
  Lwt_stream.iter_s (fun reply_parts ->
    match reply_parts with
    | [`Bulk (Some "message"); `Bulk (Some channel); `Bulk (Some message_content)] ->
        let%lwt () = Monitoring.Log.debug "Received message from Redis" ~data:[("channel", channel)] () in
        (try
          let proto_event = Schemas_generated.Input.decode_pb_input_event (Pbrt.Decoder.of_string message_content) in
          match event_of_protobuf proto_event with
          | Some (trace_id, event) ->
              let* () = Queue.push state.event_queue (Some trace_id, event) in
              let* () = Monitoring.Log.debug "Pushed event to internal queue" ~data:[("trace_id", trace_id)] () in
              Lwt.return_unit
          | None ->
              let* () = Monitoring.Log.warn "Protobuf message resulted in no engine event" ~data:[("trace_id", proto_event.trace_id)] () in
              Lwt.return_unit
        with exn ->
          let* () = Monitoring.Log.error "Deserialization failed" ~data:[("exception", Exn.to_string exn)] () in
          Lwt.return_unit)
    | [`Bulk (Some "subscribe"); _channel; _] ->
        (* Subscription ack *)
        Lwt.return_unit
    | _ ->
        let%lwt () = Monitoring.Log.warn "Unhandled reply pattern from Redis" () in
        Lwt.return_unit
  ) reply_stream

let tick (state : State.t) =
  let start_time = Unix.gettimeofday () in
  let delta = start_time -. state.last_tick in
  let* () = Lwt_unix.sleep (Float.max 0.0 (0.01 -. delta)) in
  State.update_tick state;
  Lwt.return_unit

let rec process_event (state : State.t) (trace_id : string option) (event : Event.t) =
  if Dispatcher.has_handler (string_of_event_type event) then
    Dispatcher.dispatch state trace_id event
  else
    (* Fallback simple publisher for utility events *)
    Simple_event_publisher.process_event state trace_id event

and process_events (state : State.t) =
  let start_time = Unix.gettimeofday () in
  let rec process_all () =
    match%lwt Infra.Queue.pop_opt state.event_queue with
    | None ->
        let duration = Unix.gettimeofday () -. start_time in
        Monitoring.Metrics.observe_duration "event_processing_duration_seconds" duration;
        Lwt.return_unit
    | Some (trace_id_opt, event) ->
        let event_type = string_of_event_type event in
        let trace_id_str = Option.value trace_id_opt ~default:"N/A" in
        Monitoring.Metrics.inc (Printf.sprintf "events_processed_total{type=\"%s\"}" event_type);
        let%lwt result = process_event state trace_id_opt event in
        let%lwt () = match result with
        | Ok () -> Lwt.return_unit
        | Error err ->
            let err_str = Qed_error.to_string err in
            let* () = Monitoring.Log.error "Event processing failed" ~data:[("type", event_type); ("error", err_str); ("trace_id", trace_id_str)] () in
            Monitoring.Metrics.inc (Printf.sprintf "event_errors_total{type=\"%s\"}" event_type);
            (match Event.get_user_id event with
            | Some user_id ->
                let%lwt _ = Publisher.publish_system_message_to_user state ?trace_id:trace_id_opt user_id ("Error: " ^ err_str) in
                Lwt.return_unit
            | None -> Lwt.return_unit)
        in
        process_all ()
  in
  process_all ()

let rec game_loop (state : State.t) =
  Lwt.catch
    (fun () ->
      let loop_start_time = Unix.gettimeofday () in
      let* () = Lwt_io.flush Lwt_io.stdout in
      let* () = tick state in
      let* () = process_events state in
      let* () = Ecs.World.step () in
      let* () =
        Lwt.catch
          (fun () ->
            let sync_start_time = Unix.gettimeofday () in
            let* () = Ecs.World.sync_to_db () in
            let sync_duration = Unix.gettimeofday () -. sync_start_time in
            Monitoring.Metrics.observe_duration "db_sync_duration_seconds" sync_duration;
            Lwt.return_unit)
          (fun exn ->
            let* () = Monitoring.Log.error "Database sync error in game loop" ~data:[("exception", Exn.to_string exn)] () in
            Lwt.return_unit) in
      Monitoring.Metrics.observe_duration "game_loop_duration_seconds" (Unix.gettimeofday () -. loop_start_time);
      game_loop state)
    (fun exn ->
      let* () = Monitoring.Log.error "Game loop error" ~data:[("exception", Exn.to_string exn)] () in
      game_loop state)

let run (state : State.t) =
  let* init_result = Ecs.World.init state.redis_conn in
  match init_result with
  | Ok () ->
      let* () = Dispatcher.register_legacy_systems () in
      Lwt.join [subscribe_to_player_commands state; game_loop state]
  | Error e ->
      let err_msg = Base.Error.to_string_hum e in
      let* () = Monitoring.Log.error "World initialization error" ~data:[("error", err_msg)] () in
      Lwt.return_unit
