module Handler : Client_handler.S = struct
  (* Helper functions *)

  (* World generation logic *)
  (* let handle_world_generation (state : State.t) (client : Client.t) =
    Client_handler.with_super_admin_check client (fun _character ->
        (* Delete existing world except starting area *)
        let%lwt _result =
          Area.delete_all_except_starting_area
            "00000000-0000-0000-0000-000000000000"
        in

        (* Generate world using WorldGen module *)
        let params =
          {
            World_gen.seed = 43;
            width = 20;   (* -10 to 10 *)
            height = 20;  (* -10 to 10 *)
            depth = 1;   (* -5 to 5 *)
            elevation_scale = 15.0;  (* smoother, more gradual elevation changes *)
            temperature_scale = 12.0; (* experiment to see how the climate variation feels *)
            moisture_scale = 14.0;    (* adjust for desired moisture variation *)
            vertical_scale = 2.5;     (* tuned for multi-layered worlds *)
            latitude_effect = 0.3;   (* How much latitude affects temperature *)
          }
        in

        let%lwt _coord_map = World_gen.generate_and_create_world params client in

        let%lwt () =
          World_gen_llm.generate_world state client
            ~location_id:"00000000-0000-0000-0000-000000000000"
        in

        (* Notify client and broadcast update *)
        let%lwt () =
          Client_handler.send_success client
            "World generation completed successfully"
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
        Lwt.return_unit) *)

  (* World deletion logic *)
  (* let handle_world_deletion (state : State.t) (client : Client.t) =
    Client_handler.with_super_admin_check client (fun character ->
        match%lwt
          Area.delete_all_except_starting_area character.location_id
        with
        | Error _ -> Client_handler.send_error client "Failed to delete world"
        | Ok () ->
            let%lwt () =
              Client_handler.send_success client "World deleted successfully"
            in
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
            Lwt.return_unit) *)

  (* Main message handler *)
  let handle (_state : State.t) (_client : Client.t) (msg : Protocol.client_message) =
    match msg with
    (* | RequestWorldGeneration -> handle_world_generation state client
    | RequestWorldDeletion -> handle_world_deletion state client *)
    | _ -> Lwt.return_unit
end
