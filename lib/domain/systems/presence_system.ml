open Base
open Infra
open Error_utils

module PlayerMovedLogic : System.S with type event = Event.player_moved_payload = struct
  let name = "PlayerMoved"
  type event = Event.player_moved_payload
  let event_type = function Event.PlayerMoved e -> Some e | _ -> None

  let get_character_name_by_user_id state user_id =
    match State.get_active_character state user_id with
    | None -> Lwt.return_none
    | Some char_entity_id ->
        let char_id_str = Uuidm.to_string char_entity_id in
        let%lwt char_res = Character.find_by_id char_id_str in
        (match char_res with
        | Ok (Some char_record) -> Lwt.return (Some char_record.name)
        | _ -> Lwt.return_none)

  let execute state trace_id (payload : event) =
    let { Event.user_id = user_id; Event.new_area_id = new_area_id; _ } = payload in
    let open Lwt_result.Syntax in
    let* char_name_opt = get_character_name_by_user_id state user_id |> Lwt.map Result.return in

    let* () =
      match char_name_opt with
      | None -> Lwt.return_ok ()
      | Some char_name ->
          let arrival_msg_content = Printf.sprintf "%s has arrived." char_name in
          let* arrival_msg =
            Communication.create
              ~message_type:System
              ~sender_id:None
              ~content:arrival_msg_content
              ~area_id:(Some new_area_id)
          in
          wrap_ok (Queue.push state.event_queue (trace_id, Event.Announce { area_id = new_area_id; message = arrival_msg }))
    in

    let* () = wrap_ok (Queue.push state.event_queue (trace_id, Event.AreaQuery { user_id; area_id = new_area_id })) in
    Lwt.return_ok ()
end
module PlayerMoved = System.Make(PlayerMovedLogic)