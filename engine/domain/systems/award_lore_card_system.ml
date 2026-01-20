open Base
open Infra

module AwardLoreCardLogic : System.S with type event = Event.award_lore_card_payload = struct
  let name = "AwardLoreCard"
  type event = Event.award_lore_card_payload

  let event_type = function
    | Event.AwardLoreCard e -> Some e
    | _ -> None

  let execute state trace_id ({ character_id; template_id; context } : event) =
    (* Immediately return; perform work in background *)
    Lwt.async (fun () ->
      let open Lwt.Syntax in

      (* 1. Establish dedicated connection *)
      let* conn_result =
        let db_uri = Config.Database.(to_uri (from_env ())) in
        Caqti_lwt_unix.connect db_uri
      in
      match conn_result with
      | Error e ->
          let* () = Infra.Monitoring.Log.error "AwardLoreCard connection failed"
                       ~data:[ ("caqti_error", Caqti_error.show e) ] () in
          Lwt.return_unit
      | Ok conn_module ->
          (* 2. Define the work to run using this connection *)
          let process () : (unit, Qed_error.t) Result.t Lwt.t =
            let open Lwt_result.Syntax in

            (* 2a. Log start *)
            let* () = Error_utils.wrap_ok (Infra.Monitoring.Log.debug "AwardLoreCard async start"
                                              ~data:[ ("character_id", character_id); ("template_id", template_id) ] ()) in

            (* 2b. Fetch character *)
            let* char_opt = Character.find_by_id ~conn:conn_module character_id () in
            let* char_rec = match char_opt with
              | Some c -> Lwt_result.return c
              | None -> Lwt_result.fail Qed_error.CharacterNotFound
            in
            let user_id = char_rec.user_id in

            (* 2c. Determine metadata *)
            let* (title, description) =
              match context with
              | Some ctx -> Lore_card_generator.generate_metadata ~context:ctx
              | None ->
                  let* tmpl_opt = Lore_card.find_template_by_id ~conn:conn_module template_id () in
                  let* tmpl = match tmpl_opt with
                    | Some t -> Lwt_result.return t
                    | None ->
                        Lwt_result.return (Lore_card.Template.{ id = "unknown"; card_name = "Unknown";
                                                               power_cost = 0; required_saga_tier = 1;
                                                               default_title = None; default_description = None;
                                                               bonus_1_type = None; bonus_1_value = None;
                                                               bonus_2_type = None; bonus_2_value = None;
                                                               bonus_3_type = None; bonus_3_value = None;
                                                               grants_ability = None })
                  in
                  let title = Option.value tmpl.default_title ~default:tmpl.card_name in
                  let description = Option.value tmpl.default_description ~default:"" in
                  Lwt.return (Ok (title, description))
            in

            (* 2d. Persist new instance *)
            let* card_instance =
              Lore_card.create_instance ~conn:conn_module ~character_id ~template_id ~title ~description ()
            in

            (* 2e. Enqueue follow-up event *)
            let* () = Error_utils.wrap_ok (State.enqueue ?trace_id state (Event.LoreCardAwarded { user_id; card = card_instance })) in
            Lwt_result.return ()
          in

          (* 3. Ensure we disconnect afterwards *)
          let finalize () =
            let module Db = (val conn_module : Caqti_lwt.CONNECTION) in
            Db.disconnect ()
          in

          (* 4. Run and log any failure *)
          let%lwt result = Lwt.finalize process finalize in
          (match result with
           | Ok () -> Lwt.return_unit
           | Error err ->
               let raw =
                 match err with
                 | Qed_error.DatabaseError msg -> msg
                 | _ -> Qed_error.to_string err
               in
               let* () = Infra.Monitoring.Log.error "Failed to award lore card" ~data:[
                 ("wrapped", Qed_error.to_string err);
                 ("raw", raw);
                 ("character_id", character_id);
                 ("template_id", template_id)
               ] () in
               Lwt.return_unit)
    ) ;
    Lwt.return_ok ()
end

module AwardLoreCard = System.Make (AwardLoreCardLogic) 