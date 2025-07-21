open Base
open Infra
open Qed_domain

(* Genesis transaction: seeds item definitions, areas, exits, and initial item instances *)
let genesis_transaction (world_data : Seeding.t)
    (module Db : Caqti_lwt.CONNECTION) =
  let open Lwt_result.Syntax in
  let* () = Db.start () in

  (* 1. Seed Item Definitions *)
  let item_insert_req =
    let open Caqti_type.Std in
    Caqti_request.Infix.((t8 string string string string string float bool (option string) ->. unit)
        "INSERT INTO item_definitions (id, name, description, item_type, slot, weight, is_stackable, properties) VALUES (?, ?, ?, ?, ?, ?, ?, ?::jsonb) ON CONFLICT (id) DO NOTHING")
  in
  let rec insert_item_defs = function
    | [] -> Lwt_result.return ()
    | idef :: rest ->
        let open Item_definition in
        let props_str = Option.map idef.properties ~f:Yojson.Safe.to_string in
        let* () = Db.exec item_insert_req
          (idef.id, idef.name, idef.description,
           item_type_to_string idef.item_type,
           slot_to_string idef.slot, idef.weight, idef.is_stackable, props_str)
        in
        insert_item_defs rest
  in
  let* () = insert_item_defs (Seeding.get_item_definitions world_data) in

  (* 2. Seed Areas *)
  let area_insert_req =
    let open Caqti_type.Std in
    Caqti_request.Infix.((t9 string string string int int int (option float) (option float) (option float) ->. unit)
        "INSERT INTO areas (id, name, description, x, y, z, climate_elevation, climate_temperature, climate_moisture) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING")
  in
  let rec insert_areas = function
    | [] -> Lwt_result.return ()
    | (id, name, description, x, y, z, _items) :: rest ->
        let* () = Db.exec area_insert_req (id, name, description, x, y, z, None, None, None) in
        insert_areas rest
  in
  let* () = insert_areas (Seeding.get_areas world_data) in

  (* Helper to compute opposite direction *)
  let opposite_direction_str = function
    | "north" -> "south"
    | "south" -> "north"
    | "east" -> "west"
    | "west" -> "east"
    | "up" -> "down"
    | "down" -> "up"
    | other -> failwith ("Invalid direction: " ^ other)
  in

  let exit_insert_req =
    let open Caqti_type.Std in
    Caqti_request.Infix.((t7 string string string string (option string) bool bool ->. unit)
        "INSERT INTO exits (id, from_area_id, to_area_id, direction, description, hidden, locked) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING")
  in

  let rec insert_exits = function
    | [] -> Lwt_result.return ()
    | (from_id, to_id, direction_str) :: rest ->
        let fwd_id = Uuidm.to_string (Uuidm.v4_gen (Stdlib.Random.State.make_self_init ()) ()) in
        let back_id = Uuidm.to_string (Uuidm.v4_gen (Stdlib.Random.State.make_self_init ()) ()) in
        let back_direction = opposite_direction_str direction_str in
        let* () = Db.exec exit_insert_req (fwd_id, from_id, to_id, direction_str, None, false, false) in
        let* () = Db.exec exit_insert_req (back_id, to_id, from_id, back_direction, None, false, false) in
        insert_exits rest
  in
  let* () = insert_exits (Seeding.get_exits world_data) in

  let entity_insert_req = Caqti_request.Infix.(Caqti_type.string ->. Caqti_type.unit) "INSERT INTO entities (id) VALUES (?) ON CONFLICT (id) DO NOTHING" in
  let items_table_insert_req = Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit) "INSERT INTO items (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO NOTHING" in
  let pos_table_insert_req = Caqti_request.Infix.(Caqti_type.(t2 string string) ->. Caqti_type.unit) "INSERT INTO item_positions (entity_id, data) VALUES (?, ?) ON CONFLICT (entity_id) DO NOTHING" in

  let rec insert_items_in_area = function
    | [] -> Lwt_result.return ()
    | (item_def_id, quantity, area_id) :: rest_items ->
        let item_entity_id_str = Uuidm.to_string (Uuidm.v4_gen (Stdlib.Random.State.make_self_init ()) ()) in
        let* () = Db.exec entity_insert_req item_entity_id_str in
        let item_comp = Components.ItemComponent.{ entity_id = item_entity_id_str; item_definition_id = item_def_id; quantity } in
        let item_comp_json = Components.ItemComponent.to_yojson item_comp |> Yojson.Safe.to_string in
        let* () = Db.exec items_table_insert_req (item_entity_id_str, item_comp_json) in
        let pos_comp = Components.ItemPositionComponent.{ entity_id = item_entity_id_str; area_id } in
        let pos_comp_json = Components.ItemPositionComponent.to_yojson pos_comp |> Yojson.Safe.to_string in
        let* () = Db.exec pos_table_insert_req (item_entity_id_str, pos_comp_json) in
        insert_items_in_area rest_items
  in

  let rec seed_area_items = function
    | [] -> Lwt_result.return ()
    | (_id, _name, _desc, _x, _y, _z, items_to_spawn) :: rest_areas ->
        let* () = insert_items_in_area items_to_spawn in
        seed_area_items rest_areas
  in
  let* () = seed_area_items (Seeding.get_areas world_data) in

  (* 3. Seed Lore Card Templates *)
  let lct_insert_req =
    let open Caqti_type.Std in
    Caqti_request.Infix.( (t11 string string int int (option string) (option int) (option string) (option int) (option string) (option int) (option string)) ->. unit)
      {| INSERT INTO lore_card_templates
           (id, card_name, power_cost, required_saga_tier,
            bonus_1_type, bonus_1_value,
            bonus_2_type, bonus_2_value,
            bonus_3_type, bonus_3_value,
            grants_ability)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING |}
  in

  let rec insert_templates = function
    | [] -> Lwt_result.return ()
    | (id, name, cost, tier, b1t, b1v, b2t, b2v, b3t, b3v, ability) :: rest ->
        let* () = Db.exec lct_insert_req (id, name, cost, tier, b1t, b1v, b2t, b2v, b3t, b3v, ability) in
        insert_templates rest
  in
  let* () = insert_templates (Seeding.get_lore_card_templates world_data) in

  Db.commit ()

let () =
  let config = Config.Database.from_env () in
  match Lwt_main.run (Infra.Database.Pool.connect config) with
  | Error err ->
      Stdio.prerr_endline ("Failed to connect to database: " ^ Error.to_string_hum err);
      Stdlib.exit 1
  | Ok () ->
      Stdio.print_endline "Database connected. Reading world.json...";
      (match Seeding.from_file "world.json" with
      | Error e ->
          Stdio.eprintf "Failed to parse world.json: %s\n" e;
          Stdlib.exit 1
      | Ok world_data ->
          Stdio.print_endline "Seeding world...";
          let result =
            Lwt_main.run
              (Infra.Database.Pool.use (genesis_transaction world_data))
          in
          (match result with
          | Ok () ->
              Stdio.print_endline "Genesis complete. World seeded successfully.";
              Stdlib.exit 0
          | Error e ->
              Stdio.eprintf
                "Genesis failed: %s\n" (Error.to_string_hum e);
              Stdlib.exit 1)) 