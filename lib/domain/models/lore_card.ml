open Base
open Infra

module Template = struct
  type t = {
    id : string;
    card_name : string;
    power_cost : int;
    required_saga_tier : int;
    bonus_1_type : string option;
    bonus_1_value : int option;
    bonus_2_type : string option;
    bonus_2_value : int option;
    bonus_3_type : string option;
    bonus_3_value : int option;
    grants_ability : string option;
  }
end

module Instance = struct
  type t = {
    id : string;
    character_id : string;
    template_id : string;
    title : string;
    description : string;
    is_active : bool;
  }
end

(* UUID generator *)
let uuid = Uuidm.v4_gen (Stdlib.Random.State.make_self_init ())

module Q = struct
  (* Custom caqti types *)
  let template_type : Template.t Caqti_type.t =
    let open Template in
    Caqti_type.custom
      ~encode:(fun {
                 id;
                 card_name;
                 power_cost;
                 required_saga_tier;
                 bonus_1_type;
                 bonus_1_value;
                 bonus_2_type;
                 bonus_2_value;
                 bonus_3_type;
                 bonus_3_value;
                 grants_ability;
               } ->
        Ok
          ( id,
            card_name,
            power_cost,
            required_saga_tier,
            bonus_1_type,
            bonus_1_value,
            bonus_2_type,
            bonus_2_value,
            bonus_3_type,
            bonus_3_value,
            grants_ability ))
      ~decode:(fun ( id,
                      card_name,
                      power_cost,
                      required_saga_tier,
                      bonus_1_type,
                      bonus_1_value,
                      bonus_2_type,
                      bonus_2_value,
                      bonus_3_type,
                      bonus_3_value,
                      grants_ability ) ->
        Ok
          {
            id;
            card_name;
            power_cost;
            required_saga_tier;
            bonus_1_type;
            bonus_1_value;
            bonus_2_type;
            bonus_2_value;
            bonus_3_type;
            bonus_3_value;
            grants_ability;
          })
      Caqti_type.Std.(t11 string string int int (option string) (option int) (option string) (option int) (option string) (option int) (option string))
  ;;
  let instance_type : Instance.t Caqti_type.t =
    let open Instance in
    Caqti_type.custom
      ~encode:(fun { id; character_id; template_id; title; description; is_active } ->
        Ok (id, character_id, template_id, title, description, is_active))
      ~decode:(fun (id, character_id, template_id, title, description, is_active) ->
        Ok { id; character_id; template_id; title; description; is_active })
      Caqti_type.Std.(t6 string string string string string bool)
  ;;

  (* Combined type for instance + template *)
  let instance_with_template_type : (Instance.t * Template.t) Caqti_type.t =
    Caqti_type.Std.t2 instance_type template_type
  ;;

  let find_active_with_templates =
    Caqti_request.Infix.(Caqti_type.Std.string ->* instance_with_template_type)
      {| SELECT plc.id, plc.character_id, plc.template_id, plc.title, plc.description, plc.is_active,
               tmpl.id, tmpl.card_name, tmpl.power_cost, tmpl.required_saga_tier,
               tmpl.bonus_1_type, tmpl.bonus_1_value,
               tmpl.bonus_2_type, tmpl.bonus_2_value,
               tmpl.bonus_3_type, tmpl.bonus_3_value,
               tmpl.grants_ability
         FROM player_lore_cards plc
         JOIN lore_card_templates tmpl ON plc.template_id = tmpl.id
         WHERE plc.character_id = ? AND plc.is_active = TRUE |}
  ;;

  (* Fetch template via instance ID using a JOIN for efficiency *)
  let find_template_by_instance_id =
    Caqti_request.Infix.(Caqti_type.Std.string ->? template_type)
      {| SELECT tmpl.id, tmpl.card_name, tmpl.power_cost, tmpl.required_saga_tier,
               tmpl.bonus_1_type, tmpl.bonus_1_value,
               tmpl.bonus_2_type, tmpl.bonus_2_value,
               tmpl.bonus_3_type, tmpl.bonus_3_value,
               tmpl.grants_ability
         FROM lore_card_templates tmpl
         JOIN player_lore_cards plc ON tmpl.id = plc.template_id
         WHERE plc.id = ? |}
  ;;

  (* Queries *)
  let insert_instance =
    Caqti_request.Infix.(instance_type ->. Caqti_type.unit)
      {| INSERT INTO player_lore_cards
           (id, character_id, template_id, title, description, is_active)
         VALUES (?, ?, ?, ?, ?, ?) |}

  let find_template_by_id =
    Caqti_request.Infix.(Caqti_type.Std.string ->? template_type)
      {| SELECT id, card_name, power_cost, required_saga_tier,
               bonus_1_type, bonus_1_value,
               bonus_2_type, bonus_2_value,
               bonus_3_type, bonus_3_value,
               grants_ability
         FROM lore_card_templates
         WHERE id = ? |}

  let find_instances_by_character_id =
    Caqti_request.Infix.(Caqti_type.Std.string ->* instance_type)
      {| SELECT id, character_id, template_id, title, description, is_active
         FROM player_lore_cards
         WHERE character_id = ? |}

  let find_active_instances_by_character_id =
    Caqti_request.Infix.(Caqti_type.Std.string ->* instance_type)
      {| SELECT id, character_id, template_id, title, description, is_active
         FROM player_lore_cards
         WHERE character_id = ? AND is_active = TRUE |}

  let set_active_status =
    Caqti_request.Infix.(Caqti_type.Std.(t2 bool string) ->. Caqti_type.unit)
      {| UPDATE player_lore_cards SET is_active = ? WHERE id = ? |}
end

let create_instance ~character_id ~template_id ~title ~description =
  let id = Uuidm.to_string (uuid ()) in
  let record =
    Instance.{
      id;
      character_id;
      template_id;
      title;
      description;
      is_active = false;
    }
  in
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.exec Q.insert_instance record with
    | Ok () -> Lwt_result.return record
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok r -> Lwt.return_ok r
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))

let find_template_by_id template_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.find_opt Q.find_template_by_id template_id with
    | Ok tmpl_opt -> Lwt_result.return tmpl_opt
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok tmpl_opt -> Lwt.return_ok tmpl_opt
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))

let find_instances_by_character_id character_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.collect_list Q.find_instances_by_character_id character_id with
    | Ok list -> Lwt_result.return list
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok list -> Lwt.return_ok list
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))

let find_active_instances_by_character_id character_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.collect_list Q.find_active_instances_by_character_id character_id with
    | Ok list -> Lwt_result.return list
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok list -> Lwt.return_ok list
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))

let find_active_instances_with_templates character_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.collect_list Q.find_active_with_templates character_id with
    | Ok rows -> Lwt_result.return rows
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok rows -> Lwt.return_ok rows
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err))

let set_active_status ~instance_id ~is_active =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.exec Q.set_active_status (is_active, instance_id) with
    | Ok () -> Lwt_result.return ()
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok () -> Lwt.return_ok ()
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err)) 

let find_template_by_instance_id instance_id =
  let db_operation (module Db : Caqti_lwt.CONNECTION) =
    match%lwt Db.find_opt Q.find_template_by_instance_id instance_id with
    | Ok tmpl_opt -> Lwt_result.return tmpl_opt
    | Error e -> Lwt_result.fail e
  in
  match%lwt Database.Pool.use db_operation with
  | Ok tmpl_opt -> Lwt.return_ok tmpl_opt
  | Error err -> Lwt.return_error (Qed_error.DatabaseError (Error.to_string_hum err)) 