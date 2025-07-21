open Base
open Infra
open Qed_domain

let register_systems () =
  let open Scheduler in
  let r_event ?before ?after event_name handler =
    register ?before ?after ~name:event_name ~schedule:Update ~criteria:(OnEvent event_name)
      (fun s t e_opt ->
        match e_opt with
        | Some e -> handler s t (Some e)
        | None -> Lwt.return_ok ())
  in
  let r_tick name schedule handler =
    register ~name ~schedule ~criteria:OnTick handler
  in
  let r_change ?before ?after name schedule component_name handler =
    register ?before ?after ~name ~schedule ~criteria:(OnComponentChange component_name) handler
  in

  (* Event-based Systems *)
  r_event "TakeItem" Item_system.TakeItem.handle;
  r_event "DropItem" Item_system.DropItem.handle;
  r_event "RequestInventory" Item_system.RequestInventory.handle;
  r_event "Equip" Equipment_system.Equip.handle;
  r_event "Unequip" Equipment_system.Unequip.handle;
  r_event ~after:["CreateCharacter"] "CharacterListRequested" Character_system.CharacterList.handle;
  r_event "CreateCharacter" Character_system.CharacterCreate.handle;
  r_event "CharacterSelected" Character_system.CharacterSelect.handle;
  r_event "LoadCharacterIntoECS" Character_loading_system.LoadCharacter.handle;
  r_event "UnloadCharacterFromECS" Character_unloading_system.UnloadCharacter.handle;
  r_event "Move" Movement_system.Move.handle;
  r_event "PlayerMoved" Presence_system.PlayerMoved.handle;
  r_event "Say" Communication_system.Say.handle;
  r_event "Announce" Communication_system.Announce.handle;
  r_event "Tell" Communication_system.Tell.handle;
  r_event "RequestChatHistory" Communication_system.RequestChatHistory.handle;
  r_event "SendChatHistory" Communication_system.SendChatHistory.handle;
  r_event "AreaQuery" Area_management_system.AreaQuery.handle;
  r_event "AreaQueryResult" Area_management_system.AreaQueryResult.handle;
  r_event "LoadAreaIntoECS" Area_loading_system.LoadArea.handle;
  r_event "RequestAdminMetrics" Metrics_system.RequestMetrics.handle;
  r_event "RequestCharacterSheet" Character_sheet_system.RequestCharacterSheet.handle;

  (* Progression & Lore Card Systems *)
  r_event "AwardExperience" Experience_system.AwardExperience.handle;
  r_event ~after:["AwardExperience"] "PlayerGainedExperience" Progression_system.CheckForProgression.handle;
  r_event "AwardLoreCard" Award_lore_card_system.AwardLoreCard.handle;

  (* Lore Card Loadout Systems *)
  r_event "ActivateLoreCard" Manage_loadout_system.ActivateLoreCard.handle;
  r_event "DeactivateLoreCard" Manage_loadout_system.DeactivateLoreCard.handle;
  r_event ~after:["ActivateLoreCard"; "DeactivateLoreCard"] "LoadoutChanged" Stat_recalculation_system.RecalculateStats.handle;
  r_event "RequestLoreCollection" Request_lore_collection_system.RequestLoreCollection.handle;

  (* Tick-based Systems *)
  r_tick "ApRegen" Update Ap_regen_system.APRegen.handle;
  r_tick "Recovery" Update Recovery_system.Recovery.handle;
  r_tick "EntityCleanup" PostUpdate Entity_cleanup_system.EntityCleanup.handle;

  (* PostUpdate tickable systems *)
  r_tick "EquipmentUpdate" PostUpdate Equipment_update_system.EquipmentUpdate.handle;

  (* Change-based Systems *)
  r_change ~after:["damage-application"] "Knockout" Update "healths" Knockout_system.Knockout.handle;
  r_change "BonusStatRecalculation" Update "equipments" Bonus_stat_recalculation_system.BonusStatRecalculation.handle;
  ()

let () =
  let config = Config.Database.from_env () in
  match Lwt_main.run (Database.Pool.connect config) with
  | Error err ->
      Stdio.prerr_endline ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok () ->
      register_systems ();
      Stdio.print_endline "All systems registered with scheduler.";

      Stdio.print_endline "Database connected successfully";
      Lwt_main.run
        (let open Lwt.Syntax in
        let redis_host = Stdlib.Sys.getenv_opt "REDIS_HOST" |> Option.value ~default:"127.0.0.1" in
        let redis_port =
          match Stdlib.Sys.getenv_opt "REDIS_PORT" with
          | None -> 6379
          | Some port_str -> ( try Int.of_string port_str with _ -> 6379 )
        in
        let* redis = Redis_lwt.Client.connect { host = redis_host; port = redis_port } in
        let app_state = State.create redis in
        Loop.run app_state)
