module System = struct
  let handle_player_moved (state : State.t) user_id _old_area_id new_area_id =
    (* TODO: Broadcast "Player has left" to old_area_id *)
    (* TODO: Broadcast "Player has arrived" to new_area_id *)

    (* Send the new area info to the player who moved *)
    let%lwt () = Infra.Queue.push state.event_queue
      (Event.AreaQuery { user_id; area_id = new_area_id })
    in
    Lwt_result.return ()
end