open Base
open Qed_error

module MoveLogic : System.S with type event = Event.move_payload = struct
  let name = "Move"
  type event = Event.move_payload
  let event_type = function Event.Move e -> Some e | _ -> None

  let execute state _trace_id ({ user_id; direction } : event) =
    let open Lwt_result.Syntax in
    let* character = Character_actions.find_active ~state ~user_id |> Lwt.map (Result.map_error ~f:(fun s -> LogicError s)) in

    match%lwt Character_actions.move ~state ~character ~direction with
    | Ok () -> Lwt_result.return ()
    | Error reason ->
        let* () = Character_actions.send_message ~state ~character ~message:reason in
        Lwt_result.return ()
end
module Move = System.Make(MoveLogic)