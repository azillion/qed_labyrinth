let handle_character_creation (_state : State.t) (client : Client.t) (name : string) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { user_id; _ } ->
      (let%lwt result = Qed_domain.Character.create ~user_id ~name in
      match result with
      | Ok character -> (
          let () = Client.set_character client character.id in
          let character' = Api.Types.character_of_model character in
          let character_json = Api.Types.character_to_yojson character' in
          let%lwt () = client.send (Api.Protocol.CharacterCreated character_json) in
          (* TODO: Send Area message *)
          match%lwt Qed_domain.Area.find_by_id character.location_id with
          | Error _ -> Lwt.return_unit
          | Ok area -> (
              match%lwt Qed_domain.Area.get_exits area with
              | Error _ -> Lwt.return_unit
              | Ok exits -> (
                  let area' = Api.Types.area_of_model area exits in
                  let%lwt () = client.send (Api.Protocol.Area { area = area' }) in
                  Lwt.return_unit)))
      | Error error ->
          let error_json = Qed_domain.Character.error_to_yojson error in
          let%lwt () = client.send (Api.Protocol.CharacterCreationFailed { error = error_json }) in
          Lwt.return_unit)


let handle_character_list (_state : State.t) (client : Client.t) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { user_id; _ } ->
      let%lwt result = Qed_domain.Character.find_all_by_user ~user_id in
      match result with
      | Ok characters ->
          let characters' = List.map Api.Types.character_of_model characters in
          let%lwt () = client.send (Api.Protocol.CharacterList { characters = characters' }) in
          Lwt.return_unit
      | Error error ->
          let error_json = Qed_domain.Character.error_to_yojson error in
          let%lwt () = client.send (Api.Protocol.CharacterListFailed { error = error_json }) in
          Lwt.return_unit

let handle_character_select (_state : State.t) (client : Client.t) (character_id : string) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated _ ->
      match%lwt Qed_domain.Character.find_by_id character_id with
      | Ok character -> (
          let () = Client.set_character client character.id in
          let character' = Api.Types.character_of_model character in
          let%lwt () = client.send (Api.Protocol.CharacterSelected { character = character' }) in
          (* TODO: Send Area message *)
          match%lwt Qed_domain.Area.find_by_id character.location_id with
          | Error _ -> Lwt.return_unit
          | Ok area -> (
              match%lwt Qed_domain.Area.get_exits area with
              | Error _ -> Lwt.return_unit
              | Ok exits -> (
                  let area' = Api.Types.area_of_model area exits in
                  let%lwt () = client.send (Api.Protocol.Area { area = area' }) in
                  Lwt.return_unit)))
      | Error error ->
          let error_json = Qed_domain.Character.error_to_yojson error in
          let%lwt () = client.send (Api.Protocol.CharacterSelectionFailed { error = error_json }) in
          Lwt.return_unit

let handle_message (state : State.t) (client : Client.t)
    (message : Api.Protocol.client_message) =
  match message with
  | CreateCharacter { name } -> handle_character_creation state client name
  | SelectCharacter { character_id } -> handle_character_select state client character_id
  | ListCharacters -> handle_character_list state client