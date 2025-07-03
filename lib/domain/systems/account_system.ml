open Base
open Qed_error
open Ecs

let find_user_entity_by_username username =
  let%lwt auth_components = AuthenticationStorage.all () in
  Lwt.return (List.find_map auth_components ~f:(fun (entity_id, comp) ->
    if String.equal comp.username username then Some entity_id else None))

let hash_password password =
  Digestif.SHA256.digest_string password |> Digestif.SHA256.to_hex

let authenticate ~username ~password =
  let open Lwt_result.Syntax in
  let* user_entity_id_opt = find_user_entity_by_username username |> Lwt_result.ok in
  match user_entity_id_opt with
  | None -> Lwt.return_error UserNotFound
  | Some user_entity_id ->
    let* auth_comp_opt = AuthenticationStorage.get user_entity_id |> Lwt_result.ok in
    let* profile_comp_opt = UserProfileStorage.get user_entity_id |> Lwt_result.ok in
    match auth_comp_opt, profile_comp_opt with
    | Some auth_comp, Some profile_comp ->
        let password_hash = hash_password password in
        if String.equal auth_comp.password_hash password_hash then
          Lwt.return_ok (user_entity_id, profile_comp.role)
        else
          Lwt.return_error InvalidPassword
    | _, _ -> Lwt.return_error UserNotFound

let register ~username ~password ~email =
  let open Lwt_result.Syntax in
  let* existing_user = find_user_entity_by_username username |> Lwt_result.ok in
  match existing_user with
  | Some _ -> Lwt.return_error UsernameTaken
  | None ->
      (* We will skip email uniqueness check for now to keep the step simple. *)
      let* entity_id = Entity.create () |> Lwt.map (Result.map_error ~f:(fun _ -> DatabaseError "Failed to create entity")) in
      let entity_id_str = Uuidm.to_string entity_id in

      let auth_comp = Components.AuthenticationComponent.{
        entity_id = entity_id_str;
        username;
        password_hash = hash_password password;
        token = None;
        token_expires_at = None;
      } in

      let profile_comp = Components.UserProfileComponent.{
        entity_id = entity_id_str;
        email;
        role = Components.UserProfileComponent.Player;
        created_at = Unix.time ();
      } in

      let* () = AuthenticationStorage.set entity_id auth_comp |> Lwt_result.ok in
      let* () = UserProfileStorage.set entity_id profile_comp |> Lwt_result.ok in
      Lwt.return_ok (entity_id, Components.UserProfileComponent.Player)

let update_token ~user_entity_id ~token ~expires_at =
    let open Lwt_result.Syntax in
    let* auth_comp_opt = AuthenticationStorage.get user_entity_id |> Lwt_result.ok in
    match auth_comp_opt with
    | None -> Lwt.return_error UserNotFound
    | Some auth_comp ->
        let new_auth_comp = { auth_comp with token; token_expires_at = expires_at } in
        let* () = AuthenticationStorage.set user_entity_id new_auth_comp |> Lwt_result.ok in
        Lwt.return_ok ()