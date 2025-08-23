open Base
open Yojson.Safe.Util
open Error_utils

module NpcSpawnLogic : System.S with type event = Event.spawn_npc_payload = struct
  let name = "SpawnNpc"
  type event = Event.spawn_npc_payload
  let event_type = function Event.SpawnNpc e -> Some e | _ -> None

  let execute _state _trace_id ({ archetype_id; location_id } : event) =
    let open Lwt_result.Syntax in
    (* 1. Fetch the archetype blueprint *)
    let* archetype_opt = Archetype.find_by_id archetype_id in
    let* archetype = archetype_opt |> Result.of_option ~error:(Qed_error.LogicError "Archetype not found") |> Lwt.return in

    (* 2. Generate unique details via LLM *)
    let traits = archetype.params |> member "behavior" |> member "traits" |> to_list |> List.map ~f:to_string in
    let desc_prompt = archetype.prompts |> member "description_base" |> to_string in
    let system_prompt = "You are a world-building assistant for a fantasy game. Respond ONLY with valid JSON in the form {\"name\": \"<name>\", \"description\": \"<description>\"}." in
    let user_prompt = String.substr_replace_all desc_prompt ~pattern:"{traits}" ~with_:(String.concat ~sep:", " traits) in
    
    let* llm_json =
      match%lwt Infra.Ai_gateway.json_completion ~system:system_prompt ~user:user_prompt with
      | Ok j -> Lwt.return_ok j
      | Error msg -> Lwt.return_error (Qed_error.UnknownError msg)
    in
    let name = llm_json |> member "name" |> to_string_option |> Option.value ~default:"Nameless" in
    let description = llm_json |> member "description" |> to_string_option |> Option.value ~default:"An ordinary creature." in

    (* 3. Create the master NPC record *)
    let* npc_record = Npc.create ~archetype_id ~name ~description in
    let entity_id = Uuidm.of_string npc_record.id |> Option.value_exn in
    let* () = wrap_ok (Infra.Monitoring.Log.info "NPC entity created" ~data:[("name", name); ("id", npc_record.id); ("archetype", archetype_id)] ()) in

    (* 4. Attach ECS components based on the archetype *)
    let params = archetype.params in
    let phys_params = params |> member "physicality" in
    
    let* () = wrap_ok (Components.ArchetypeComponent.{ entity_id = npc_record.id; archetype_id } |> Ecs.ArchetypeStorage.set entity_id) in
    let* () = wrap_ok (Components.CharacterPositionComponent.{ entity_id = npc_record.id; area_id = location_id } |> Ecs.CharacterPositionStorage.set entity_id) in
    let* () = wrap_ok (Components.PhysicalityComponent.{ entity_id = npc_record.id; can_speak = phys_params |> member "can_speak" |> to_bool; can_manipulate_objects = phys_params |> member "can_manipulate_objects" |> to_bool } |> Ecs.PhysicalityStorage.set entity_id) in
    let* () = wrap_ok (Components.BehaviorComponent.{ entity_id = npc_record.id; traits } |> Ecs.BehaviorStorage.set entity_id) in
    let* () = wrap_ok (Components.GoalComponent.{ entity_id = npc_record.id; active_goal = "Idle"; context = `Null } |> Ecs.GoalStorage.set entity_id) in

    (* 5. Populate initial inventory *)
    let initial_items = params |> member "initial_inventory" |> to_list in
    let* item_entity_ids = Lwt_list.map_s (fun item_json ->
        let def_id = item_json |> member "item_definition_id" |> to_string in
        let qty = item_json |> member "quantity" |> to_int in
        let item_entity_id = Uuidm.v4_gen (Stdlib.Random.State.make_self_init ()) () in
        let item_comp = Components.ItemComponent.{ entity_id = Uuidm.to_string item_entity_id; item_definition_id = def_id; quantity = qty } in
        let%lwt () = Ecs.ItemStorage.set item_entity_id item_comp in
        Lwt.return (Uuidm.to_string item_entity_id)
      ) initial_items |> wrap_val
    in
    let* () = wrap_ok (Components.InventoryComponent.{ entity_id = npc_record.id; items = item_entity_ids } |> Ecs.InventoryStorage.set entity_id) in

    Lwt_result.return ()
end

module NpcSpawner = System.Make(NpcSpawnLogic)


