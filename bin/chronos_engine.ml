open Base
open Infra
open Qed_domain

let register_systems () =
  let open Scheduler in
  let r event_name handler =
    register ~schedule:Update ~criteria:(OnEvent event_name) (fun s t e_opt ->
      handler s t e_opt)
  in
  r "TakeItem" Item_system.TakeItem.handle;
  r "DropItem" Item_system.DropItem.handle;
  r "RequestInventory" Item_system.RequestInventory.handle;
  r "CharacterListRequested" Character_system.CharacterList.handle;
  r "CreateCharacter" Character_system.CharacterCreate.handle;
  r "CharacterSelected" Character_system.CharacterSelect.handle;
  r "LoadCharacterIntoECS" Character_loading_system.LoadCharacter.handle;
  r "UnloadCharacterFromECS" Character_unloading_system.UnloadCharacter.handle;
  r "Move" Movement_system.Move.handle;
  r "PlayerMoved" Presence_system.PlayerMoved.handle;
  r "Say" Communication_system.Say.handle;
  r "Announce" Communication_system.Announce.handle;
  r "Tell" Communication_system.Tell.handle;
  r "RequestChatHistory" Communication_system.RequestChatHistory.handle;
  r "SendChatHistory" Communication_system.SendChatHistory.handle;
  r "AreaQuery" Area_management_system.AreaQuery.handle;
  r "AreaQueryResult" Area_management_system.AreaQueryResult.handle;
  r "LoadAreaIntoECS" Area_loading_system.LoadArea.handle;
  r "RequestAdminMetrics" Metrics_system.RequestMetrics.handle

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
