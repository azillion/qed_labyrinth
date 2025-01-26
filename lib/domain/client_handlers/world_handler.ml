module Handler : Client_handler.S = struct
  (* Helper functions *)
  let send_error (client : Client.t) error =
    client.send (Protocol.CommandFailed { error })

  let send_success (client : Client.t) message =
    let%lwt msg =
      Communication.create ~message_type:Communication.CommandSuccess
        ~sender_id:None ~content:message ~area_id:None
    in
    match msg with
    | Ok msg ->
        client.send
          (Protocol.CommandSuccess { message = Types.chat_message_of_model msg })
    | Error _ -> Lwt.return_unit

  (* World generation helpers *)
  let get_room_name (climate : Area.climate) =
    match
      Area.get_room_type
        {
          id = "";
          name = "";
          description = "";
          x = 0;
          y = 0;
          z = 0;
          elevation = Some climate.elevation;
          temperature = Some climate.temperature;
          moisture = Some climate.moisture;
        }
    with
    | Some Area.Cave -> "Cave"
    | Some Area.Forest -> "Forest"
    | Some Area.Mountain -> "Mountain Peak"
    | Some Area.Swamp -> "Swamp"
    | Some Area.Desert -> "Desert"
    | Some Area.Tundra -> "Frozen Wastes"
    | Some Area.Lake -> "Lakeshore"
    | Some Area.Canyon -> "Canyon"
    | None -> "Unknown Area"

  let opposite_direction = function
    | Area.North -> Area.South
    | Area.South -> Area.North
    | Area.East -> Area.West
    | Area.West -> Area.East
    | Area.Up -> Area.Down
    | Area.Down -> Area.Up

  (* World generation logic *)
  let handle_world_generation (state : State.t) (client : Client.t) =
    Client_handler.with_super_admin_check client (fun _character ->
        (* Delete existing world except starting area *)
        let%lwt _result =
          Area.delete_all_except_starting_area
            "00000000-0000-0000-0000-000000000000"
        in

        (* Generate world using Perlin noise *)
        let params =
          {
            World_gen.WorldGen.seed = 42;
            width = 10;
            height = 10;
            depth = 9;
            elevation_scale = 15.0;
            temperature_scale = 20.0;
            moisture_scale = 18.0;
          }
        in

        let noise_gens = World_gen.WorldGen.create_generators params.seed in
        let coord_map =
          Hashtbl.create (params.width * params.height * params.depth)
        in

        (* Generate and create areas *)
        let rec create_areas x y z =
          if z >= params.depth then
            Lwt.return_unit
          else if y >= params.height then
            create_areas x 0 (z + 1)
          else if x >= params.width then
            create_areas 0 (y + 1) z
          else if x = 0 && y = 0 && z = 0 then
            (* Skip starting area coordinates *)
            create_areas (x + 1) y z
          else
            let climate =
              World_gen.WorldGen.generate_climate params noise_gens (x, y, z)
            in
            let name = get_room_name climate in
            match%lwt
              Area.create_with_climate ~name
                ~description:
                  (Area.get_climate_description
                     {
                       id = "";
                       name = "";
                       description = "";
                       x;
                       y;
                       z;
                       elevation = Some climate.elevation;
                       temperature = Some climate.temperature;
                       moisture = Some climate.moisture;
                     })
                ~x ~y ~z
                ~climate
                ()
            with
            | Ok area ->
                Hashtbl.add coord_map (x, y, z) area.id;
                create_areas (x + 1) y z
            | Error _ -> create_areas (x + 1) y z
        in

        let%lwt () = create_areas 0 0 0 in

        (* Add starting area to coord_map *)
        let%lwt () =
          match%lwt Area.find_by_id "00000000-0000-0000-0000-000000000000" with
          | Ok area ->
              Hashtbl.add coord_map (0, 0, 0) area.id;
              Lwt.return_unit
          | Error _ -> Lwt.return_unit
        in

        (* Create exits between areas *)
        let%lwt () =
          Hashtbl.fold
            (fun (x, y, z) area_id acc ->
              let directions =
                [
                  (Area.North, (0, 0, 1));
                  (Area.South, (0, 0, -1));
                  (Area.East, (1, 0, 0));
                  (Area.West, (-1, 0, 0));
                  (Area.Up, (0, 1, 0));
                  (Area.Down, (0, -1, 0));
                ]
              in
              let%lwt () = acc in
              Lwt_list.iter_s
                (fun (dir, (dx, dy, dz)) ->
                  let tx = x + dx in
                  let ty = y + dy in
                  let tz = z + dz in
                  match Hashtbl.find_opt coord_map (tx, ty, tz) with
                  | Some target_id ->
                      let%lwt _ =
                        Area.create_exit ~from_area_id:area_id
                          ~to_area_id:target_id ~direction:dir ~description:None
                          ~hidden:false ~locked:false
                      in
                      let%lwt _ =
                        Area.create_exit ~from_area_id:target_id
                          ~to_area_id:area_id
                          ~direction:(opposite_direction dir) ~description:None
                          ~hidden:false ~locked:false
                      in
                      Lwt.return_unit
                  | None -> Lwt.return_unit)
                directions)
            coord_map Lwt.return_unit
        in

        (* Notify client and broadcast update *)
        let%lwt () =
          send_success client "World generation completed successfully"
        in
        Connection_manager.broadcast state.connection_manager
          (Protocol.CommandSuccess
             {
               message =
                 {
                   message_type = Communication.CommandSuccess;
                   sender_id = None;
                   content = "The world has been regenerated!";
                   area_id = None;
                   timestamp = Unix.time ();
                 };
             });
        Lwt.return_unit)

  (* World deletion logic *)
  let handle_world_deletion (state : State.t) (client : Client.t) =
    Client_handler.with_super_admin_check client (fun character ->
        match%lwt
          Area.delete_all_except_starting_area character.location_id
        with
        | Error _ -> send_error client "Failed to delete world"
        | Ok () ->
            let%lwt () = send_success client "World deleted successfully" in
            Connection_manager.broadcast state.connection_manager
              (Protocol.CommandSuccess
                 {
                   message =
                     {
                       message_type = Communication.CommandSuccess;
                       sender_id = None;
                       content = "The world has been reset!";
                       area_id = None;
                       timestamp = Unix.time ();
                     };
                 });
            Lwt.return_unit)

  (* Main message handler *)
  let handle state client msg =
    let open Protocol in
    match msg with
    | RequestWorldGeneration -> handle_world_generation state client
    | RequestWorldDeletion -> handle_world_deletion state client
    | _ -> Lwt.return_unit
end
