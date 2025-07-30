open Base
open Infra
open Error_utils

module CheckForProgressionLogic : System.S with type event = Event.player_gained_experience_payload = struct
  let name = "CheckForProgression"
  type event = Event.player_gained_experience_payload

  let event_type = function
    | Event.PlayerGainedExperience e -> Some e
    | _ -> None

  (* SQL request to increment proficiency level and set current_xp *)
  module Q = struct
    let level_up =
      Caqti_request.Infix.(Caqti_type.Std.(t3 int int string) ->. Caqti_type.unit)
        "UPDATE characters SET proficiency_level = ?, current_xp = ? WHERE id = ?"

    let tier_up =
      Caqti_request.Infix.(Caqti_type.Std.(t3 int int string) ->. Caqti_type.unit)
        "UPDATE characters SET saga_tier = ?, current_ip = ? WHERE id = ?"
  end

  let execute state trace_id ({ Event.character_id } : event) =
    let open Lwt_result.Syntax in
    (* Fetch current character record *)
    let* char_opt = Character.find_by_id character_id () in
    match char_opt with
    | None -> Lwt.return_ok ()
    | Some c ->
        let open Character in
        (* ---------------- Level Up Logic ---------------- *)
        let* () =
          let xp_needed = Game_balance.xp_for_level c.proficiency_level in
          if c.current_xp >= xp_needed then (
            let new_level = c.proficiency_level + 1 in
            let new_xp = c.current_xp - xp_needed in
            (* Update DB *)
            let db_op (module Db : Caqti_lwt.CONNECTION) =
              Db.exec Q.level_up (new_level, new_xp, c.id)
            in
            let* () = (
              match%lwt Database.Pool.use db_op with
              | Ok () -> Lwt_result.return ()
              | Error err -> Lwt_result.fail (Qed_error.DatabaseError (Error.to_string_hum err))
            ) in

            (* Fire PlayerLeveledUp event *)
            let new_power_budget = Game_balance.power_budget_for_level new_level in
            let* () =
              wrap_ok
                (State.enqueue ?trace_id state
                   (Event.PlayerLeveledUp { user_id = c.user_id; new_level; new_power_budget }))
            in
            Lwt_result.return ()
          ) else Lwt_result.return ()
        in
        (* ---------------- Saga Tier Logic ---------------- *)
        let* () =
          let ip_needed = Game_balance.ip_for_tier c.saga_tier in
          if c.current_ip >= ip_needed then (
            let new_tier = c.saga_tier + 1 in
            let new_ip = c.current_ip - ip_needed in
            let db_op (module Db : Caqti_lwt.CONNECTION) =
              Db.exec Q.tier_up (new_tier, new_ip, c.id)
            in
            let* () = (
              match%lwt Database.Pool.use db_op with
              | Ok () -> Lwt_result.return ()
              | Error err -> Lwt_result.fail (Qed_error.DatabaseError (Error.to_string_hum err))
            ) in

            let* () = Monitoring.Log.info "Saga tier advanced" ~data:[("character_id", c.id); ("new_tier", Int.to_string new_tier)] () |> wrap_ok in
            Lwt_result.return ()
          ) else Lwt_result.return ()
        in
        Lwt_result.return ()
end

module CheckForProgression = System.Make (CheckForProgressionLogic) 