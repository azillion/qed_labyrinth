open Base

module RequestLoreCollectionLogic : System.S with type event = Event.request_lore_collection_payload = struct
  let name = "RequestLoreCollection"
  type event = Event.request_lore_collection_payload
  let event_type = function Event.RequestLoreCollection e -> Some e | _ -> None

  let execute state trace_id (p : event) =
    let open Lwt_result.Syntax in
    let { Event.user_id; character_id } = p in

    (* Fetch all lore card instances for the character *)
    let* instances = Lore_card.find_instances_by_character_id character_id in

    (* Helper to build protobuf instance *)
    let build_pb (inst : Lore_card.Instance.t) =
      let open Lwt_result.Syntax in
      let* tmpl_opt = Lore_card.find_template_by_id inst.template_id () in
      let power, bonuses_list =
        match tmpl_opt with
        | Some t ->
            let make_bonus typ v =
              { Schemas_generated.Output.type_ = typ; value = Int32.of_int_exn v } in
            let mk opt_t opt_v =
              match opt_t, opt_v with
              | Some typ, Some v -> Some (make_bonus typ v)
              | _ -> None
            in
            let b1 = mk t.bonus_1_type t.bonus_1_value in
            let b2 = mk t.bonus_2_type t.bonus_2_value in
            let b3 = mk t.bonus_3_type t.bonus_3_value in
            let bonuses = List.filter_map [b1; b2; b3] ~f:Fn.id in
            (t.power_cost, bonuses)
        | None -> (0, [])
      in
      let pb_inst : Schemas_generated.Output.lore_card_instance = {
        id = inst.id;
        template_id = inst.template_id;
        title = inst.title;
        description = inst.description;
        is_active = inst.is_active;
        power_cost = Int32.of_int_exn power;
        bonuses = bonuses_list;
      } in
      Lwt_result.return pb_inst
    in

    let build_results = List.map instances ~f:build_pb in
    let rec gather acc = function
      | [] -> Lwt_result.return (List.rev acc)
      | h::t ->
          let* v = h in
          gather (v::acc) t
    in
    let* pb_list = gather [] build_results in
    let collection_msg : Schemas_generated.Output.lore_card_collection = { cards = pb_list } in
    let output_event : Schemas_generated.Output.output_event = {
      target_user_ids = [ user_id ];
      payload = Lore_card_collection collection_msg;
      trace_id = Option.value trace_id ~default:"";
    } in
    let* () = Publisher.publish_event state ?trace_id output_event in
    Lwt_result.return ()
end

module RequestLoreCollection = System.Make(RequestLoreCollectionLogic) 