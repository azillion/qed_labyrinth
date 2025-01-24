let get_area_by_id_opt (area_id : string) =
  match%lwt Area.find_by_id area_id with
  | Error _ -> Lwt.return_none
  | Ok area -> (
      match%lwt Area.get_exits area with
      | Error _ -> Lwt.return_none
      | Ok exits ->
          let area' = Types.area_of_model area exits in
          Lwt.return_some area')

let broadcast_area_update (state : State.t) (area_id : string) =
  match%lwt get_area_by_id_opt area_id with
  | None -> Lwt.return_unit
  | Some area ->
      let update = Protocol.Area { area } in
      Connection_manager.broadcast_to_room state.connection_manager area_id
        update;
      Lwt.return_unit
