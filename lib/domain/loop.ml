open Lwt.Syntax
open Base
open Infra

let string_of_event_type (event : Event.t) =
  match event with
  | CreateCharacter _ -> "CreateCharacter"
  | CharacterCreated _ -> "CharacterCreated"
  | CharacterSelected _ -> "CharacterSelected"
  | Move _ -> "Move"
  | Say _ -> "Say"
  | CharacterListRequested _ -> "CharacterListRequested"
  | AreaQuery _ -> "AreaQuery"
  | AreaQueryResult _ -> "AreaQueryResult"
  | LoadAreaIntoECS _ -> "LoadAreaIntoECS"
  | PlayerMoved _ -> "PlayerMoved"
  | UpdateAreaPresence _ -> "UpdateAreaPresence"
  | AreaCreated _ -> "AreaCreated"
  | AreaCreationFailed _ -> "AreaCreationFailed"
  | ExitCreated _ -> "ExitCreated"
  | ExitCreationFailed _ -> "ExitCreationFailed"
  | SendMovementFailed _ -> "SendMovementFailed"
  | CharacterList _ -> "CharacterList"
  | LoadCharacterIntoECS _ -> "LoadCharacterIntoECS"
  | UnloadCharacterFromECS _ -> "UnloadCharacterFromECS"
  | SendChatHistory _ -> "SendChatHistory"
  | RequestChatHistory _ -> "RequestChatHistory"
  | Announce _ -> "Announce"
  | Tell _ -> "Tell"
  | Emote _ -> "Emote"
  | CharacterCreationFailed _ -> "CharacterCreationFailed"
  | CharacterSelectionFailed _ -> "CharacterSelectionFailed"
  | AreaQueryFailed _ -> "AreaQueryFailed"
  | TakeItem _ -> "TakeItem"
  | DropItem _ -> "DropItem"
  | RequestInventory _ -> "RequestInventory"
  | SendInventory _ -> "SendInventory"
  | TakeItemFailed _ -> "TakeItemFailed"
  | DropItemFailed _ -> "DropItemFailed"
  | ActionFailed _ -> "ActionFailed"
  | RequestAdminMetrics _ -> "RequestAdminMetrics"
  | CreateArea _ -> "CreateArea"
  | CreateExit _ -> "CreateExit"
  | Equip _ -> "Equip"
  | Unequip _ -> "Unequip"
  | RequestCharacterSheet _ -> "RequestCharacterSheet"
  (* Progression & Lore Card *)
  | AwardExperience _ -> "AwardExperience"
  | PlayerGainedExperience _ -> "PlayerGainedExperience"
  | PlayerLeveledUp _ -> "PlayerLeveledUp"
  | AwardLoreCard _ -> "AwardLoreCard"
  | LoreCardAwarded _ -> "LoreCardAwarded"
  | CharacterActivated _ -> "CharacterActivated"
  | ActivateLoreCard _ -> "ActivateLoreCard"
  | DeactivateLoreCard _ -> "DeactivateLoreCard"
  | LoadoutChanged _ -> "LoadoutChanged"
  | RequestLoreCollection _ -> "RequestLoreCollection"
  | PlayerDisconnected _ -> "PlayerDisconnected"
  | SpawnNpc _ -> "SpawnNpc"

let direction_of_proto = function
  | Schemas_generated.Input.North -> Components.ExitComponent.North
  | Schemas_generated.Input.South -> Components.ExitComponent.South
  | Schemas_generated.Input.East -> Components.ExitComponent.East
  | Schemas_generated.Input.West -> Components.ExitComponent.West
  | Schemas_generated.Input.Up -> Components.ExitComponent.Up
  | Schemas_generated.Input.Down -> Components.ExitComponent.Down
  | Schemas_generated.Input.Unspecified -> failwith "Unspecified direction"

let slot_of_proto = function
  | Schemas_generated.Input.None -> Item_definition.None
  | Schemas_generated.Input.Main_hand -> Item_definition.MainHand
  | Schemas_generated.Input.Off_hand -> Item_definition.OffHand
  | Schemas_generated.Input.Head -> Item_definition.Head
  | Schemas_generated.Input.Chest -> Item_definition.Chest
  | Schemas_generated.Input.Legs -> Item_definition.Legs
  | Schemas_generated.Input.Feet -> Item_definition.Feet

let event_of_protobuf (proto_event : Schemas_generated.Input.input_event) : (string * Event.t) option =
  let trace_id = proto_event.trace_id in
  match proto_event.payload with
  | None -> None
  | Some payload ->
      let event_opt =
        match payload with
        | Move move_cmd -> Some (Event.Move { user_id = proto_event.user_id; direction = direction_of_proto move_cmd.direction })
        | Say say_cmd -> Some (Event.Say { user_id = proto_event.user_id; content = say_cmd.content })
        | Create_character create_cmd ->
            (* Core attributes are now purely loadout-driven; use baseline values *)
            let baseline = 1 in
            Some (Event.CreateCharacter
                    { user_id = proto_event.user_id;
                      name = create_cmd.name;
                      description = "";
                      starting_area_id = "00000000-0000-0000-0000-000000000000";
                      might = baseline;
                      finesse = baseline;
                      wits = baseline;
                      grit = baseline;
                      presence = baseline })
        | List_characters -> Some (Event.CharacterListRequested { user_id = proto_event.user_id })
        | Select_character select_cmd -> Some (Event.CharacterSelected { user_id = proto_event.user_id; character_id = select_cmd.character_id })
        | Take take_cmd -> Some (Event.TakeItem { user_id = proto_event.user_id; character_id = take_cmd.character_id; item_entity_id = take_cmd.item_entity_id })
        | Drop drop_cmd -> Some (Event.DropItem { user_id = proto_event.user_id; character_id = drop_cmd.character_id; item_entity_id = drop_cmd.item_entity_id })
        | Request_inventory inv_cmd -> Some (Event.RequestInventory { user_id = proto_event.user_id; character_id = inv_cmd.character_id })
        | Request_admin_metrics -> Some (Event.RequestAdminMetrics { user_id = proto_event.user_id })
        | Equip equip_cmd -> Some (Event.Equip { user_id = proto_event.user_id; character_id = equip_cmd.character_id; item_entity_id = equip_cmd.item_entity_id })
        | Unequip unequip_cmd -> Some (Event.Unequip { user_id = proto_event.user_id; character_id = unequip_cmd.character_id; slot = slot_of_proto unequip_cmd.slot })
        | Request_character_sheet req_cmd -> Some (Event.RequestCharacterSheet { user_id = proto_event.user_id; character_id = req_cmd.character_id })
        | Activate_lore_card act_cmd ->
            Some (Event.ActivateLoreCard { user_id = proto_event.user_id; character_id = act_cmd.character_id; card_instance_id = act_cmd.card_instance_id })
        | Deactivate_lore_card de_cmd ->
            Some (Event.DeactivateLoreCard { user_id = proto_event.user_id; character_id = de_cmd.character_id; card_instance_id = de_cmd.card_instance_id })
        | Request_lore_collection req_cmd ->
            Some (Event.RequestLoreCollection { user_id = proto_event.user_id; character_id = req_cmd.character_id })
        | Player_disconnected ->
            Some (Event.PlayerDisconnected { user_id = proto_event.user_id })
      in
      Option.map event_opt ~f:(fun event -> (trace_id, event))

let subscribe_to_player_commands (state : State.t) =
  let redis_host = Stdlib.Sys.getenv_opt "REDIS_HOST" |> Option.value ~default:"127.0.0.1" in
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
        | Some (trace_id, event) -> Infra.Queue.push state.event_queue (Some trace_id, event)
        | None -> Monitoring.Log.warn "Protobuf message resulted in no engine event" ~data:[("trace_id", proto_event.trace_id)] ()
      with exn -> Monitoring.Log.error "Deserialization failed" ~data:[("exception", Exn.to_string exn)] ())
    | _ -> Lwt.return_unit
  ) reply_stream

let tick (state : State.t) =
  let start_time = Unix.gettimeofday () in
  let delta = start_time -. state.last_tick in
  let%lwt () = Lwt_unix.sleep (Float.max 0.0 (0.01 -. delta)) in
  State.update_tick state;
  Lwt.return_unit

let rec game_loop (state : State.t) =
  Lwt.catch
    (fun () ->
      let loop_start_time = Unix.gettimeofday () in
      let* () = tick state in
      (* Drain event queue once at start of frame *)
      let rec drain acc =
        match%lwt Infra.Queue.pop_opt state.event_queue with
        | None -> Lwt.return (List.rev acc)
        | Some (trace_id_opt, ev) ->
            drain ((trace_id_opt, ev) :: acc)
      in
      let* events_for_tick = drain [] in

      let* () = Scheduler.run ~events:events_for_tick PreUpdate state in
      let* () = Scheduler.run ~events:events_for_tick Update state in
      let* () = Scheduler.run ~events:events_for_tick PostUpdate state in
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
            Monitoring.Log.error "Database sync error in game loop" ~data:[("exception", Exn.to_string exn)] ())
      in
      Monitoring.Metrics.observe_duration "game_loop_duration_seconds" (Unix.gettimeofday () -. loop_start_time);
      game_loop state)
    (fun exn ->
      let* () = Monitoring.Log.error "Game loop error" ~data:[("exception", Exn.to_string exn)] () in
      game_loop state)

let run (state : State.t) =
  let* init_result = Ecs.World.init state.redis_conn in
  match init_result with
  | Ok () -> Lwt.join [ subscribe_to_player_commands state; game_loop state ]
  | Error e ->
      let err_msg = Base.Error.to_string_hum e in
      let* () = Monitoring.Log.error "World initialization error" ~data:[("error", err_msg)] () in
      Lwt.return_unit
