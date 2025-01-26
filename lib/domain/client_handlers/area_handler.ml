module Handler : Client_handler.S = struct
  let send_admin_map (client : Client.t) =
    Client_handler.with_super_admin_check client (fun character ->
        let open Lwt.Syntax in
        let* areas_result = Area.get_all_areas () in
        let* exits_result = Area.get_all_exits () in

        match (areas_result, exits_result) with
        | Ok areas, Ok exits ->
            let rooms =
              List.map
                (fun (area : Area.t) ->
                  let coordinate =
                    Some { Types.x = area.x; y = area.y; z = area.z }
                  in
                  {
                    Types.name = area.name;
                    description = area.description;
                    id = area.id;
                    coordinate;
                    exits =
                      List.map
                        (fun (e : Area.exit) ->
                          {
                            Types.direction =
                              Area.direction_to_string e.direction;
                          })
                        exits;
                    elevation = area.elevation;
                    temperature = area.temperature;
                    moisture = area.moisture;
                  })
                areas
            in

            let%lwt connections =
              Lwt_list.fold_left_s
                (fun acc (exit : Area.exit) ->
                  let%lwt from_area_result =
                    Area.find_by_id exit.from_area_id
                  in
                  let%lwt to_area_result = Area.find_by_id exit.to_area_id in

                  match (from_area_result, to_area_result) with
                  | Ok from_area, Ok to_area ->
                      let conn =
                        {
                          Types.from =
                            {
                              x = from_area.x;
                              y = from_area.y;
                              z = from_area.z;
                            };
                          to_ = { x = to_area.x; y = to_area.y; z = to_area.z };
                        }
                      in
                      Lwt.return (conn :: acc)
                  | _ -> Lwt.return acc)
                [] exits
            in

            let world =
              {
                Types.rooms;
                connections;
                current_location = character.location_id;
              }
            in
            client.send (Protocol.AdminMap { world })
        | Error area_error, Error exit_error ->
            Printf.printf "Error fetching areas: %s, exits: %s\n"
              (Area.error_to_string area_error)
              (Area.error_to_string exit_error);
            client.send
              (Protocol.CommandFailed
                 { error = "Error fetching areas or exits" })
        | Error area_error, _ ->
            Printf.printf "Error fetching areas: %s\n"
              (Area.error_to_string area_error);
            client.send
              (Protocol.CommandFailed
                 { error = "Error fetching areas or exits" })
        | _, Error exit_error ->
            Printf.printf "Error fetching exits: %s\n"
              (Area.error_to_string exit_error);
            client.send
              (Protocol.CommandFailed
                 { error = "Error fetching areas or exits" }))

  (* Main message handler *)
  let handle (_state : State.t) (client : Client.t) msg =
    let open Protocol in
    match msg with
    | RequestAdminMap -> send_admin_map client
    | _ -> Lwt.return_unit
end
