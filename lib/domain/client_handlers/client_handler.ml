module type S = sig
  val handle : State.t -> Client.t -> Protocol.client_message -> unit Lwt.t
end

let send_error (client : Client.t) error =
  client.send (Protocol.CommandFailed { error })

let with_super_admin_check (client : Client.t) (f : Character.t -> unit Lwt.t) =
  match client.auth_state with
  | Anonymous -> Lwt.return_unit 
  | Authenticated { character_id = None; _ } ->
      send_error client "You must select a character first"
  | Authenticated { user_id; character_id = Some character_id } ->
      match%lwt User.find_by_id user_id with
      | Error _ -> Lwt.return_unit
      | Ok user ->
          match user.role with
          | Player | Admin ->
              send_error client "You are not authorized to perform this action"
          | SuperAdmin ->
              match%lwt Character.find_by_id character_id with
              | Error _ -> send_error client "Character not found"
              | Ok character -> f character
