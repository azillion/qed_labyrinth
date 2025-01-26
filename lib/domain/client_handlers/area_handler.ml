module Handler : Client_handler.S = struct
  (* Helper functions *)
  let send_error (client : Client.t) error =
    client.send (Protocol.CommandFailed { error })

  let _send_area_info (client : Client.t) (area_id : string) =
    match%lwt Utils.get_area_by_id_opt area_id with
    | None -> Lwt.return_unit
    | Some area -> (
        let%lwt () = client.send (Protocol.Area { area }) in
        match%lwt Communication.find_by_area_id area_id with
        | Ok messages ->
            let messages' = List.map Types.chat_message_of_model messages in
            client.send (Protocol.ChatHistory { messages = messages' })
        | Error _ -> Lwt.return_unit)


        let send_admin_map (client : Client.t) =
          match client.auth_state with
          | Anonymous -> Lwt.return_unit
          | Authenticated { character_id = None; _ } -> 
              let%lwt () = send_error client "You must select a character first" in
              Lwt.return_unit
          | Authenticated { user_id; character_id = Some character_id } -> 
              match%lwt User.find_by_id user_id with
              | Error _ -> Lwt.return_unit
              | Ok user -> 
                  match user.role with
                  | Player | Admin -> 
                      let%lwt () = send_error client "You are not authorized to delete the world" in
                      Lwt.return_unit
                  | SuperAdmin -> 
                      match%lwt Character.find_by_id character_id with
                      | Error _ -> send_error client "You must select a character first"
                      | Ok character ->
          let open Lwt.Syntax in
          let* areas_result = Area.get_all_areas () in
          let* exits_result = Area.get_all_exits () in
          
          match areas_result, exits_result with
          | Ok areas, Ok exits ->
              let rooms = List.map (fun (area : Area.t) ->
                let coordinate = Some { Types.x = area.x; 
                                      y = area.y; 
                                      z = area.z } in
                { Types.name = area.name; 
                  description = area.description;
                  id = area.id;
                  coordinate;
                  exits = List.map (fun (e : Area.exit) -> 
                    { Types.direction = Area.direction_to_string e.direction }
                  ) exits }
              ) areas in
            
              let%lwt connections = Lwt_list.fold_left_s (fun acc (exit : Area.exit) ->
                let%lwt from_area_result = Area.find_by_id exit.from_area_id in
                let%lwt to_area_result = Area.find_by_id exit.to_area_id in
                
                match from_area_result, to_area_result with
                | Ok from_area, Ok to_area ->
                    let conn = {
                      Types.from = { x = from_area.x; y = from_area.y; z = from_area.z };
                      to_ = { x = to_area.x; y = to_area.y; z = to_area.z };
                    } in
                    Lwt.return (conn :: acc)
                | _ -> Lwt.return acc
              ) [] exits in
            
              let world = { Types.rooms; connections; current_location = character.location_id } in
              client.send (Protocol.AdminMap { world })
              
          | Error _, _ | _, Error _ ->
              client.send (Protocol.CommandFailed { error = "Error fetching areas or exits" })

  (* Main message handler *)
  let handle (_state : State.t) (client : Client.t) msg =
    let open Protocol in
    match msg with
    | RequestAdminMap -> send_admin_map client
    | _ -> Lwt.return_unit
end
