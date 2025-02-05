let system_prompt = {|You are a world builder for a dark fantasy MUD (Multi-User Dungeon) where civilization struggles against a hostile, twisted wilderness. Your goal is to create coherent, atmospheric areas that extend logically from the surrounding context while maintaining an unsettling, foreboding tone.|}

let user_prompt x y z nearby_areas = Printf.sprintf 
{|Generate a new area at (%d, %d, %d) that connects logically with these existing areas. DO NOT include coordinates or data in the generated area.

Area Types Available:
- Cave: Underground areas with potential dark secrets
- Forest: Twisted woodlands with ancient mysteries
- Mountain: Forbidding peaks and treacherous climbs
- Swamp: Fetid wetlands harboring ancient evils
- Desert: Harsh wastelands hiding lost ruins
- Tundra: Frozen wastes preserving ancient horrors
- Lake: Dark waters concealing unknowable depths
- Canyon: Deep ravines echoing with strange sounds
- Volcano: Burning lands touched by primal forces
- Jungle: Suffocating growth hiding predatory life

<existing_areas>
%s
</existing_areas>

Present the response in this format:

<generatedArea>
<areaName>[Evocative name]</areaName>

<description>[3-5 sentences describing the area's foreboding atmosphere and notable features]</description>

<roomType>[One of the specified area types]</roomType>
</generatedArea>|} x y z nearby_areas

let format_existing_areas (nearby_areas : Area.t list) =
  let%lwt nearby_with_exits = Lwt_list.map_s (fun area -> 
    match%lwt Area.get_exits area with
    | Ok exits -> Lwt.return (area, exits)
    | Error _ -> Lwt.return (area, [])
  ) nearby_areas in
  
  let existing_areas = List.map (fun ((area, _exits) : Area.t * Area.exit list) -> 
    Printf.sprintf "<area>
    Area (%d, %d, %d): 
    Name: %s
    Description: %s
    Moisture: %s
    Temperature: %s
    Elevation: %s
  </area>"
    area.x area.y area.z 
    area.name
    area.description
    (Option.value ~default:"unknown" (Option.map string_of_float area.moisture))
    (Option.value ~default:"unknown" (Option.map string_of_float area.temperature))
    (Option.value ~default:"unknown" (Option.map string_of_float area.elevation))
  ) nearby_with_exits in
  Lwt.return (String.concat "\n" existing_areas)

let extract_content_opt tag text =
  let open Re in
  let pattern = Printf.sprintf {|<%s>(.*?)</%s>|} tag tag in
  let regex = compile (Perl.re ~opts:[`Dotall] pattern) in
  match exec_opt regex text with
  | Some group -> Some (Group.get group 1 |> String.trim)
  | None -> None

let rec retry_with_backoff ~attempts ~max_attempts f =
  if attempts >= max_attempts then
    Lwt.return None
  else
    match%lwt f () with
    | Some result -> Lwt.return (Some result)
    | None ->
        let backoff_time = Float.pow 2.0 (float_of_int attempts) |> int_of_float in
        let%lwt () = Lwt_unix.sleep (float_of_int backoff_time) in
        retry_with_backoff ~attempts:(attempts + 1) ~max_attempts f

let generate_area_description location_id =
  match%lwt Area.find_by_id location_id with
  | Error _ -> Lwt.return_unit
  | Ok area ->
      let x = area.x in
      let y = area.y in
      let z = area.z in
      Stdio.print_endline (Printf.sprintf "Generating chunk at (%d, %d, %d)" x y z);
      match%lwt Area.get_all_nearby_areas location_id ~max_distance:1 with
      | Error _ -> Lwt.return_unit
      | Ok nearby_areas ->
          let generate_once () =
            let%lwt existing_areas = format_existing_areas nearby_areas in
            let user_prompt = user_prompt x y z existing_areas in
            match%lwt Infra.Llm_client.generate_with_openai ~system_prompt ~user_prompt with
            | Error err ->
                Stdio.print_endline ("Error generating area: " ^ err);
                Lwt.return None
            | Ok text -> 
                let area_name = extract_content_opt "areaName" text in
                let description = extract_content_opt "description" text in
                match area_name, description with
                | Some name, Some desc -> Lwt.return (Some (name, desc))
                | _ -> 
                    Stdio.print_endline "No area name or description found";
                    Lwt.return None
          in
          match%lwt retry_with_backoff ~attempts:0 ~max_attempts:3 generate_once with
          | None ->
              Stdio.print_endline "Failed to generate area after all retries";
              Lwt.return_unit
          | Some (area_name, description) ->
              match%lwt Area.update_area_name_and_description ~location_id ~name:area_name ~description with
              | Ok () -> Lwt.return_unit
              | Error _ ->
                  Stdio.print_endline "Error updating area";
                  Lwt.return_unit

let generate_world _state client ~(location_id : string) =
  let%lwt () = Client_handler.send_success client "Generating world with LLM" in
  
  (* Set to keep track of visited area IDs *)
  let open Base in
  let visited = Hashtbl.create (module String) ~size:256 in
  
  (* Queue for BFS traversal *)
  let queue = Queue.create () in
  Queue.enqueue queue location_id;
  Hashtbl.add_exn visited ~key:location_id ~data:();
  
  let rec process_queue () =
    if Queue.is_empty queue then
      Lwt.return_unit
    else
      let current_id = Queue.dequeue_exn queue in
      let%lwt () = 
        if String.equal current_id location_id then
          Lwt.return_unit
        else
          generate_area_description current_id 
      in
      
      (* Get exits and add unvisited areas to queue *)
      match%lwt Area.find_exits ~area_id:current_id with
      | Error _ -> process_queue ()
      | Ok exits ->
          let%lwt () = Lwt_list.iter_s
            (fun (exit : Area.exit) ->
              if not (Hashtbl.mem visited exit.to_area_id) then begin
                Hashtbl.add_exn visited ~key:exit.to_area_id ~data:();
                Queue.enqueue queue exit.to_area_id;
                Lwt.return_unit
              end else
                Lwt.return_unit)
            exits
          in
          process_queue ()
  in
  
  process_queue ()