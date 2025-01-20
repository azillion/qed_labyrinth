let handle_character_creation (_state : State.t) (client : Client.t) (name : string) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit
  | Authenticated { user_id; _ } ->
      (let%lwt result = Qed_domain.Character.create ~user_id ~name in
      match result with
      | Ok character ->
          let character' = Api.Types.character_of_model character in
          let character_json = Api.Types.character_to_yojson character' in
          let%lwt () = client.send (Api.Protocol.CharacterCreated character_json) in
          Lwt.return_unit
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

let handle_message (state : State.t) (client : Client.t)
    (message : Api.Protocol.client_message) =
  match message with
  | CreateCharacter { name } -> handle_character_creation state client name
  | SelectCharacter { character_id = _ } -> Lwt.return_unit
  | ListCharacters -> handle_character_list state client