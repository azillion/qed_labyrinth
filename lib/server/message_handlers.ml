let get_area_by_id_opt (area_id : string) =
  match%lwt Qed_domain.Area.find_by_id area_id with
  | Error _ -> Lwt.return_none
  | Ok area -> (
      match%lwt Qed_domain.Area.get_exits area with
      | Error _ -> Lwt.return_none
      | Ok exits ->
          let area' = Api.Types.area_of_model area exits in
          Lwt.return_some area')

let handle_character_creation (_state : State.t) (client : Client.t)
    (name : string) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { user_id; _ } -> (
      let%lwt result = Qed_domain.Character.create ~user_id ~name in
      match result with
      | Ok character -> (
          let () = Client.set_character client character.id in
          let character' = Api.Types.character_of_model character in
          let character_json = Api.Types.character_to_yojson character' in
          let%lwt () =
            client.send (Api.Protocol.CharacterCreated character_json)
          in
          (* TODO: Send Area message *)
          match%lwt get_area_by_id_opt character.location_id with
          | None -> Lwt.return_unit
          | Some area ->
              let%lwt () = client.send (Api.Protocol.Area { area }) in
              Lwt.return_unit)
      | Error error ->
          let error_json = Qed_domain.Character.error_to_yojson error in
          let%lwt () =
            client.send
              (Api.Protocol.CharacterCreationFailed { error = error_json })
          in
          Lwt.return_unit)

let handle_character_list (_state : State.t) (client : Client.t) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { user_id; _ } -> (
      let%lwt result = Qed_domain.Character.find_all_by_user ~user_id in
      match result with
      | Ok characters ->
          let characters' = List.map Api.Types.character_of_model characters in
          let%lwt () =
            client.send
              (Api.Protocol.CharacterList { characters = characters' })
          in
          Lwt.return_unit
      | Error error ->
          let error_json = Qed_domain.Character.error_to_yojson error in
          let%lwt () =
            client.send
              (Api.Protocol.CharacterListFailed { error = error_json })
          in
          Lwt.return_unit)

let handle_character_select (_state : State.t) (client : Client.t)
    (character_id : string) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated _ -> (
      match%lwt Qed_domain.Character.find_by_id character_id with
      | Ok character -> (
          let () = Client.set_character client character.id in
          let character' = Api.Types.character_of_model character in
          let%lwt () =
            client.send
              (Api.Protocol.CharacterSelected { character = character' })
          in
          (* TODO: Send Area message *)
          match%lwt get_area_by_id_opt character.location_id with
          | None -> Lwt.return_unit
          | Some area ->
              let%lwt () = client.send (Api.Protocol.Area { area }) in
              Lwt.return_unit)
      | Error error ->
          let error_json = Qed_domain.Character.error_to_yojson error in
          let%lwt () =
            client.send
              (Api.Protocol.CharacterSelectionFailed { error = error_json })
          in
          Lwt.return_unit)

let handle_command (_state : State.t) (client : Client.t) (command_str : string)
    =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { character_id = None; _ } ->
      let%lwt () =
        client.send
          (Api.Protocol.CommandFailed
             { error = "You must select a character first" })
      in
      Lwt.return_unit
  | Authenticated { character_id = Some character_id; _ } -> (
      let open Api.Types in
      match parse_command command_str with
      | Move { direction } -> (
          let%lwt result = Qed_domain.Character.move ~character_id ~direction in
          match result with
          | Error _ ->
              let%lwt () =
                client.send
                  (Api.Protocol.CommandFailed
                     { error = "Cannot move in that direction" })
              in
              Lwt.return_unit
          | Ok new_location -> (
              match%lwt get_area_by_id_opt new_location with
              | None -> Lwt.return_unit
              | Some area ->
                  let%lwt () = client.send (Api.Protocol.Area { area }) in
                  Lwt.return_unit))
      | Help ->
          let%lwt () =
            client.send
              (Api.Protocol.CommandSuccess
                 {
                   message =
                     "Available commands:\n\
                      n, s, e, w, u, d - Move in a direction\n\
                      look - Look at current room\n\
                      help - Show this message";
                 })
          in
          Lwt.return_unit
      | Unknown cmd ->
          let%lwt () =
            client.send
              (Api.Protocol.CommandFailed { error = "Unknown command: " ^ cmd })
          in
          Lwt.return_unit)

let handle_message (state : State.t) (client : Client.t)
    (message : Api.Protocol.client_message) =
  match message with
  | CreateCharacter { name } -> handle_character_creation state client name
  | SelectCharacter { character_id } ->
      handle_character_select state client character_id
  | ListCharacters -> handle_character_list state client
  | Command { command } -> handle_command state client command
