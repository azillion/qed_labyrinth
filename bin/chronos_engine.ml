open Base
open Infra
open Qed_domain

let () =
  let config = Config.Database.from_env () in
  match Lwt_main.run (Database.Pool.connect config) with
  | Error err ->
      Stdio.prerr_endline
        ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok () ->
      (* --- Register Systems --- *)
      let () =
        Dispatcher.register "TakeItem" Item_system.TakeItem.handle;
        Dispatcher.register "DropItem" Item_system.DropItem.handle;
        Dispatcher.register "RequestInventory" Item_system.RequestInventory.handle;
        Dispatcher.register "CharacterListRequested" Character_system.CharacterList.handle;
        Dispatcher.register "CreateCharacter" Character_system.CharacterCreate.handle;
        Dispatcher.register "CharacterSelected" Character_system.CharacterSelect.handle;
        Dispatcher.register "LoadCharacterIntoECS" Character_loading_system.LoadCharacter.handle;
        Dispatcher.register "UnloadCharacterFromECS" Character_unloading_system.UnloadCharacter.handle;
        Dispatcher.register "Move" Movement_system.Move.handle;
        Dispatcher.register "PlayerMoved" Presence_system.PlayerMoved.handle;
        (* Communication systems *)
        Dispatcher.register "Say" Communication_system.Say.handle;
        Dispatcher.register "Announce" Communication_system.Announce.handle;
        Dispatcher.register "Tell" Communication_system.Tell.handle;
        Dispatcher.register "RequestChatHistory" Communication_system.RequestChatHistory.handle;
        Dispatcher.register "SendChatHistory" Communication_system.SendChatHistory.handle;
        (* Area management systems *)
        Dispatcher.register "AreaQuery" Area_management_system.AreaQuery.handle;
        Dispatcher.register "AreaQueryResult" Area_management_system.AreaQueryResult.handle;
        Dispatcher.register "LoadAreaIntoECS" Area_loading_system.LoadArea.handle
      in
      Stdio.print_endline "All systems registered.";
      (* --- End System Registration --- *)

      Stdio.print_endline "Database connected successfully";
      Lwt_main.run (
        let open Lwt.Syntax in
        let redis_host = Stdlib.Sys.getenv_opt "REDIS_HOST" |> Option.value ~default:"127.0.0.1" in
        let redis_port =
          match Stdlib.Sys.getenv_opt "REDIS_PORT" with
          | None -> 6379
          | Some port_str ->
              try Int.of_string port_str with _ -> 6379
        in
        let* redis = Redis_lwt.Client.connect { host = redis_host; port = redis_port } in
        let app_state = State.create redis in
        Loop.run app_state
      )
