open Utils
open Lwt.Syntax

type world_params = {
  seed : int;
  width : int;
  height : int;
  depth : int;
  elevation_scale : float;
  temperature_scale : float;
  moisture_scale : float;
  vertical_scale : float;
  latitude_effect : float;
}

type geological_era = {
  era_seed : int;
  tectonic_activity : float; (* 0-1 scale of geological activity *)
  erosion_level : float;     (* 0-1 scale of erosion *)
  volcanic_activity : float; (* 0-1 scale of volcanic presence *)
  era_weight : float;
  duration : float;
}

type microclimate = {
  local_temp_mod : float;
  local_moisture_mod : float;
  wind_effect : float;
  shadow_effect : float;
  precipitation : float;
  air_pressure : float;
}

type biome_transition = {
  primary_biome : Area.room_type;
  secondary_biome : Area.room_type;
  blend_factor : float;
}

type generation_batch = {
  coords : (int * int * int) list;
  created_areas : (int * int * int, string) Hashtbl.t;
}

type area_passability =
  | FreeMovement
  | DifficultTerrain
  | Blocked

let batch_size = 500
let sky_elevation = 0.7
let frozen_temperature = -0.3

let calculate_era_weights eras =
  let total_duration = List.fold_left (fun acc era -> acc +. era.duration) 0.0 eras in
  List.map (fun era -> { era with era_weight = era.duration /. total_duration }) eras

let geological_history seed =
  let eras = [
    { era_seed = seed;
      tectonic_activity = 0.9;
      erosion_level = 0.1;
      volcanic_activity = 0.8;
      era_weight = 0.0;
      duration = 1.0 };
    { era_seed = seed + 1;
      tectonic_activity = 0.5;
      erosion_level = 0.4;
      volcanic_activity = 0.3;
      era_weight = 0.0;
      duration = 2.0 };
    { era_seed = seed + 2;
      tectonic_activity = 0.2;
      erosion_level = 0.8;
      volcanic_activity = 0.1;
      era_weight = 0.0;
      duration = 1.5 };
  ] in
  calculate_era_weights eras

let axis_range size =
  let half = size / 2 in
  let start, finish =
    if size mod 2 = 0 then (-half, half - 1) else (-half, half)
  in
  List.init (finish - start + 1) (fun i -> start + i)

let create_generators seed =
  let base_noise = PerlinNoise.create ~seed () in
  let temp_noise = PerlinNoise.create ~seed:(seed + 1) () in
  let moist_noise = PerlinNoise.create ~seed:(seed + 2) () in
  let biome_noise = PerlinNoise.create ~seed:(seed + 3) () in
  (base_noise, temp_noise, moist_noise, biome_noise)

let generate_climate params (elev_n, temp_n, moist_n, biome_n) eras (x, y, z) =
  let base_elev = ref 0.0 in
  List.iter (fun era ->
    let era_noise = PerlinNoise.create ~seed:era.era_seed () in
    let tectonic_effect =
      (PerlinNoise.octave_noise era_noise
        (float_of_int x /. params.elevation_scale)
        (float_of_int y /. params.elevation_scale)
        (float_of_int z /. params.elevation_scale *. era.tectonic_activity)
      +. 1.0) *. 0.5  (* Convert from [-1,1] to [0,1] *)
    in
    let volcanic_effect =
      if era.volcanic_activity > 0.5 then
        let volcano_centers = PerlinNoise.create ~seed:(era.era_seed + 1) () in
        let dist =
          (PerlinNoise.octave_noise volcano_centers
            (float_of_int x /. (params.elevation_scale *. 2.0))
            (float_of_int y /. (params.elevation_scale *. 2.0))
            0.0
          +. 1.0) *. 0.5
        in
        if dist > 0.7 then era.volcanic_activity else 0.0
      else
        0.0
    in
    base_elev := !base_elev
                  +. ((tectonic_effect *. 2.0 -. 1.0) *. era.tectonic_activity)
                  +. (volcanic_effect *. 0.3)
  ) eras;

  (* Scale the elevation based on number of eras *)
  let base_elev = !base_elev /. float_of_int (List.length eras) in
  
  let erosion_factor =
    List.fold_left (fun acc era -> acc +. era.erosion_level) 0.0 eras
    /. float_of_int (List.length eras)
  in
  
  (* Calculate slope using normalized noise values *)
  let next_elev = 
    (PerlinNoise.octave_noise elev_n
       (float_of_int (x + 1) /. params.elevation_scale)
       (float_of_int y       /. params.elevation_scale)
       (float_of_int z       /. params.elevation_scale)
    +. 1.0) *. 0.5
  in
  let slope = abs_float (base_elev -. next_elev) in
  
  let eroded_elev =
    if slope > 0.3 then base_elev -. (slope *. erosion_factor *. 0.5)
    else base_elev
  in
  let elevation = max (-1.0) (min 1.0 eroded_elev) in

  let micro = {
    local_temp_mod =
      PerlinNoise.noise3d temp_n
        (float_of_int x /. (params.temperature_scale *. 0.1))
        (float_of_int y /. (params.temperature_scale *. 0.1))
        (float_of_int z /. (params.temperature_scale *. 0.1))
      *. 0.2;
    local_moisture_mod =
      PerlinNoise.noise3d moist_n
        (float_of_int x /. (params.moisture_scale *. 0.1))
        (float_of_int y /. (params.moisture_scale *. 0.1))
        (float_of_int z /. (params.moisture_scale *. 0.1))
      *. 0.2;
    wind_effect =
      (PerlinNoise.octave_noise biome_n
        (float_of_int x /. (params.elevation_scale *. 2.0))
        (float_of_int y /. (params.elevation_scale *. 2.0))
        0.0
      +. 1.0) *. 0.5;
    shadow_effect =
      if elevation > 0.5 then 0.2 *. (elevation -. 0.5) else 0.0;
    precipitation = 0.0;
    air_pressure = 0.0;
  } in

  (* Temperature calculation with better scaling *)
  let raw_temp =
    (PerlinNoise.noise3d temp_n
      (float_of_int x /. params.temperature_scale)
      (float_of_int y /. params.temperature_scale)
      (float_of_int z /. params.temperature_scale)
    +. 1.0) *. 0.5
  in
  let temperature =
    let t_alt = raw_temp -. (abs_float elevation *. 0.4) in
    let t_all = t_alt +. micro.local_temp_mod
                      -. (micro.shadow_effect *. 0.3)
                      +. (micro.wind_effect *. 0.1)
    in
    (max 0.0 (min 1.0 t_all)) *. 2.0 -. 1.0  (* Convert [0,1] to [-1,1] *)
  in

  (* Moisture calculation with better scaling *)
  let raw_moist =
    (PerlinNoise.noise3d moist_n
      (float_of_int x /. params.moisture_scale)
      (float_of_int y /. params.moisture_scale)
      (float_of_int z /. params.moisture_scale)
    +. 1.0) *. 0.5
  in
  let moisture =
    let base_moisture = raw_moist *. 2.0 -. 1.0 in (* Convert back to [-1,1] *)
    let m_all = base_moisture 
                +. (micro.local_moisture_mod *. 0.3)    (* Reduce local effect *)
                +. (micro.wind_effect *. 0.1)          (* Reduce wind effect *)
                -. (micro.shadow_effect *. 0.4)        (* Increase shadow effect *)
                -. (abs_float elevation *. 0.3)        (* Add elevation-based drying *)
    in
    max (-1.0) (min 1.0 m_all)  (* Already in [-1,1] range *)
  in
  { Area.elevation; temperature; moisture }

let compute_room_type (cl : Area.climate) =
  (* Compute a simple slope value to capture local variation.
     (Note: you might eventually want to replace this with the more complex
      `calculate_slope` logic if needed.) *)
  let slope = cl.moisture *. cl.elevation in

  if cl.elevation < -0.3 then 
    Area.Cave

  else if cl.elevation > 0.6 then
    if cl.temperature > 0.5 then 
      Area.Volcano
    else if cl.moisture > 0.5 then 
      Area.Forest
    else 
      Area.Mountain

  else if cl.temperature < -0.2 then 
    Area.Tundra

  else if cl.temperature > 0.5 && cl.moisture < 0.0 then 
    Area.Desert

  else if cl.moisture > 0.6 then
    if slope > 0.25 then 
      Area.Jungle
    else if cl.temperature > 0.4 then 
      Area.Swamp
    else 
      Area.Lake

  else if cl.elevation > 0.2 then
    (* For moderate elevation, we now distinguish between two climates:
       - If moisture is at or below 0.5 and temperature is modest (below 0.6),
         we treat the area as Grassland.
       - Otherwise, we assume a denser forest.
       Adjust these thresholds based on the distribution of your generated values.
    *)
    if cl.moisture <= 0.5 && cl.temperature < 0.6 then 
      Area.Grassland  (* NEW BIOME: consider adding Grassland to your Area.room_type definition *)
    else
      Area.Forest

  else if cl.moisture > 0.3 then 
    Area.Forest

  else 
    Area.Lake

let get_biome_transition cl =
  let p_biome = compute_room_type cl in
  let t_shift = cl.temperature +. 0.1 in
  let m_shift = cl.moisture -. 0.1 in
  let alt_biome = compute_room_type { cl with temperature = t_shift; moisture = m_shift } in
  if p_biome = alt_biome then None
  else
    let blend = abs_float t_shift +. (abs_float m_shift /. 2.0) in
    Some { primary_biome = p_biome; secondary_biome = alt_biome; blend_factor = blend }

let get_room_type_description rt transition =
  let base = match rt with
    | Area.Cave      -> "a dark cave with rough stone walls."
    | Area.Forest    -> "a forest with abundant foliage."
    | Area.Grassland -> "a grassy plain with scattered trees."
    | Area.Mountain  -> "a mountainous outcropping battered by winds."
    | Area.Swamp     -> "a swamp of mucky, waterlogged ground."
    | Area.Desert    -> "an arid desert of drifting sands."
    | Area.Tundra    -> "a frozen tundra of icy ground."
    | Area.Lake      -> "a lakeshore saturating the air with moisture."
    | Area.Canyon    -> "a canyon of looming rock walls."
    | Area.Volcano   -> "a volcanic crater exuding ash and heat."
    | Area.Jungle    -> "a dense jungle thick with humidity."
  in
  match transition with
  | None -> base
  | Some t ->
      let extra = match t.secondary_biome with
        | Area.Desert    when t.blend_factor > 0.7 -> "the soil grows sandy."
        | Area.Forest    when t.blend_factor > 0.7 -> "you notice more trees."
        | Area.Mountain  when t.blend_factor > 0.7 -> "the ground is rockier."
        | Area.Swamp     when t.blend_factor > 0.7 -> "it's feeling boggier."
        | Area.Tundra    when t.blend_factor > 0.7 -> "the air is colder."
        | Area.Jungle    when t.blend_factor > 0.7 -> "lush growth abounds."
        | _ -> ""
      in
      if extra = "" then base else base ^ " " ^ extra

(* no special z-based naming: let's just pick from the climate. *)
let get_room_name (cl : Area.climate) =
  match compute_room_type cl with
  | Area.Cave      -> "Cave"
  | Area.Forest    -> "Forest"
  | Area.Grassland -> "Grassland"
  | Area.Mountain  -> "Mountain Peak"
  | Area.Swamp     -> "Swamp"
  | Area.Desert    -> "Desert"
  | Area.Tundra    -> "Frozen Wastes"
  | Area.Lake      -> "Lakeshore"
  | Area.Canyon    -> "Canyon"
  | Area.Volcano   -> "Volcanic Crater"
  | Area.Jungle    -> "Dense Jungle"

let generate_coordinates params =
  let coords = ref [] in
  let xs = axis_range params.width in
  let ys = axis_range params.height in
  let zs = axis_range params.depth in
  List.iter (fun zz ->
    List.iter (fun yy ->
      List.iter (fun xx ->
        coords := (xx, yy, zz) :: !coords
      ) xs
    ) ys
  ) zs;
  !coords

let create_batches sz coords =
  let rec split batches current = function
    | [] ->
        if current = [] then batches else current :: batches
    | c :: rest ->
        if List.length current >= sz
        then split (current :: batches) [c] rest
        else split batches (c :: current) rest
  in
  split [] [] coords |> List.rev

let create_area_at_coord params noise_gens eras coord_map (x,y,z) =
  let climate = generate_climate params noise_gens eras (x,y,z) in
  let room_type = compute_room_type climate in
  let transition = get_biome_transition climate in
  let name = get_room_name climate in
  let description = get_room_type_description room_type transition in
  let* area_result =
    Area.create_with_climate ~name ~description ~x ~y ~z ~climate ()
  in
  match area_result with
  | Ok area ->
      Hashtbl.add coord_map (x,y,z) area.id;
      Lwt.return_unit
  | Error _ ->
      Lwt.return_unit

let process_area_batch params noise_gens eras batch =
  let coord_map = Hashtbl.create (List.length batch) in
  let* () =
    Lwt_list.iter_s (fun coord ->
      let* () = create_area_at_coord params noise_gens eras coord_map coord in
      Lwt.return_unit
    ) batch
  in
  Lwt.return coord_map

let generate_and_create_world (params : world_params) (client : Client.t) =
  let noise_gens = create_generators params.seed in
  let eras = geological_history params.seed in

  let all_coords = generate_coordinates params in
  let area_batches = create_batches batch_size all_coords in

  let* () = Client_handler.send_success client "World generation started" in

  let* area_maps =
    Lwt_list.mapi_s (fun i batch ->
      let* () =
        Client_handler.send_success client
          (Printf.sprintf "Processing areas batch %d of %d"
             (i+1) (List.length area_batches))
      in
      process_area_batch params noise_gens eras batch
    ) area_batches
  in

  let final_map = Hashtbl.create (params.width * params.height * params.depth) in
  List.iter (fun submap ->
    Hashtbl.iter (fun c id -> Hashtbl.add final_map c id) submap
  ) area_maps;

  (* still adding a 'starting area' if it exists, but not skipping generation for it. *)
  let* () =
    match%lwt Area.find_by_id "00000000-0000-0000-0000-000000000000" with
    | Ok area ->
        Hashtbl.add final_map (0,0,0) area.id;
        Lwt.return_unit
    | Error _ -> Lwt.return_unit
  in

  let* () = Client_handler.send_success client "Creating exits" in

  let coords_list = Hashtbl.fold (fun k _ acc -> k :: acc) final_map [] in

  let collect_exits_for_coords (x,y,z) =
    let area_id = Hashtbl.find final_map (x,y,z) in
    let directions = [
      (Area.North, (0, -1, 0));
      (Area.South, (0, 1, 0));
      (Area.East,  (1, 0, 0));
      (Area.West,  (-1, 0, 0));
      (Area.Up,    (0, 0, 1));
      (Area.Down,  (0, 0, -1));
    ] in
    List.fold_left (fun acc (dir, (dx,dy,dz)) ->
      let tx, ty, tz = (x+dx, y+dy, z+dz) in
      match Hashtbl.find_opt final_map (tx,ty,tz) with
      | Some targ_id ->
          (area_id, targ_id, dir) :: acc
      | None -> acc
    ) [] directions
  in

  let all_exits = List.concat_map collect_exits_for_coords coords_list in
  let exit_batch_size = 1000 in
  let exit_batches = create_batches exit_batch_size all_exits in

  let create_exit_batch exits =
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let* () =
        Lwt_list.iter_s (fun (from_id, to_id, dir) ->
          let* _ =
            Db.exec Area.Q.insert_exit {
              from_area_id = from_id;
              to_area_id = to_id;
              direction = dir;
              description = None;
              hidden = false;
              locked = false;
            }
          in
          let* _ =
            Db.exec Area.Q.insert_exit {
              from_area_id = to_id;
              to_area_id = from_id;
              direction = Area.opposite_direction dir;
              description = None;
              hidden = false;
              locked = false;
            }
          in
          Lwt.return_unit
        ) exits
      in
      Lwt_result.return ()
    in
    Infra.Database.Pool.use db_operation
  in

  let* () =
    Lwt_list.iteri_s (fun i batch ->
      let* () =
        Client_handler.send_success client
          (Printf.sprintf "Creating exits batch %d of %d"
             (i+1) (List.length exit_batches))
      in
      match%lwt create_exit_batch batch with
      | Ok () -> Lwt.return_unit
      | Error _ -> Lwt.return_unit
    ) exit_batches
  in

  let* () = Client_handler.send_success client "World generation complete" in
  Lwt.return final_map

let calculate_slope elev_n params (x,y,z) =
  let scale = params.elevation_scale in
  let vscale = params.vertical_scale in
  let dx = (PerlinNoise.octave_noise elev_n 
    ((float_of_int (x+1)) /. scale) 
    (float_of_int y /. scale) 
    (float_of_int z /. scale) +. 1.0) *. 0.5 
  in
  let dy = (PerlinNoise.octave_noise elev_n 
    (float_of_int x /. scale) 
    ((float_of_int (y+1)) /. scale) 
    (float_of_int z /. scale) +. 1.0) *. 0.5 
  in
  let dz = (PerlinNoise.octave_noise elev_n 
    (float_of_int x /. scale) 
    (float_of_int y /. scale) 
    ((float_of_int (z+1)) /. scale) +. 1.0) *. 0.5 
  in
  let current = (PerlinNoise.octave_noise elev_n 
    (float_of_int x /. scale) 
    (float_of_int y /. scale) 
    (float_of_int z /. scale) +. 1.0) *. 0.5 
  in
  let slope_x = abs_float (dx -. current) in
  let slope_y = abs_float (dy -. current) in
  let slope_z = abs_float (dz -. current) *. vscale in
  (slope_x +. slope_y +. slope_z) /. 3.0

let calculate_volcanic_effect era params x y z =
  if era.volcanic_activity <= 0.0 then 0.0 else
  let volcano_noise = PerlinNoise.create ~seed:(era.era_seed + 1) () in
  let volcanic_3d_scale = params.elevation_scale *. 1.5 in
  let dist = 
    (PerlinNoise.octave_noise volcano_noise 
      (float_of_int x /. volcanic_3d_scale) 
      (float_of_int y /. volcanic_3d_scale)
      (float_of_int z /. volcanic_3d_scale)
    +. 1.0) *. 0.5
  in
  let falloff = 1.0 -. (dist *. 1.5) in
  max 0.0 (era.volcanic_activity *. (falloff ** 2.0))
