module SendLoreCardAwardedLogic : System.S with type event = Event.lore_card_awarded_payload = struct
  open Base

  let name = "SendLoreCardAwarded"
  type event = Event.lore_card_awarded_payload

  let event_type = function
    | Event.LoreCardAwarded e -> Some e
    | _ -> None

  let execute state trace_id ({ user_id; card } : event) =
    let open Lwt_result.Syntax in
    (* Fetch template for additional data *)
    let* tmpl_opt = Lore_card.find_template_by_id card.template_id () in
    let tmpl_fallback =
      Lore_card.Template.{
        id = card.template_id;
        card_name = card.title;
        power_cost = 0;
        required_saga_tier = 1;
        default_title = None;
        default_description = None;
        bonus_1_type = None;
        bonus_1_value = None;
        bonus_2_type = None;
        bonus_2_value = None;
        bonus_3_type = None;
        bonus_3_value = None;
        grants_ability = None;
      }
    in
    let tmpl = Option.value tmpl_opt ~default:tmpl_fallback in

    let bonus_list =
      let open Schemas_generated.Output in
      let bonus_from typ_opt value_int_opt =
        match (typ_opt, value_int_opt) with
        | Some typ, Some v -> Some { type_ = typ; value = Int32.of_int_exn v }
        | _ -> None
      in
      [ bonus_from tmpl.bonus_1_type tmpl.bonus_1_value;
        bonus_from tmpl.bonus_2_type tmpl.bonus_2_value;
        bonus_from tmpl.bonus_3_type tmpl.bonus_3_value ]
      |> List.filter_map ~f:Fn.id
    in

    (* Build LoreCardInstance PB *)
    let pb_instance : Schemas_generated.Output.lore_card_instance =
      {
        id = card.id;
        template_id = card.template_id;
        title = card.title;
        description = card.description;
        is_active = card.is_active;
        power_cost = Int32.of_int_exn tmpl.power_cost;
        bonuses = bonus_list;
      }
    in

    let pb_awarded : Schemas_generated.Output.lore_card_awarded = { card = Some pb_instance } in

    let output_event : Schemas_generated.Output.output_event = {
      target_user_ids = [ user_id ];
      payload = Lore_card_awarded pb_awarded;
      trace_id = Option.value trace_id ~default:"";
    } in

    let* () = Publisher.publish_event state output_event in
    Lwt_result.return ()
end

module SendLoreCardAwarded = System.Make (SendLoreCardAwardedLogic) 