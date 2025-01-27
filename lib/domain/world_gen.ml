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
}

(* New types for enhanced generation *)
type geological_era = {
  era_seed : int;
  tectonic_activity : float; (* 0-1 scale of geological activity *)
  erosion_level : float; (* 0-1 scale of erosion *)
  volcanic_activity : float; (* 0-1 scale of volcanic presence *)
}

type microclimate = {
  local_temp_mod : float;
  local_moisture_mod : float;
  wind_effect : float;
  shadow_effect : float;
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

let batch_size = 500 (* Adjust based on testing *)
let sky_elevation = 0.7
let frozen_temperature = -0.3
let uuid seed = Uuidm.v4_gen seed ()

(* Geological eras define major world shaping events *)
let geological_history seed =
  [
    {
      era_seed = seed;
      tectonic_activity = 0.9;
      erosion_level = 0.1;
      volcanic_activity = 0.8;
    };
    {
      era_seed = seed + 1;
      tectonic_activity = 0.5;
      erosion_level = 0.4;
      volcanic_activity = 0.3;
    };
    {
      era_seed = seed + 2;
      tectonic_activity = 0.2;
      erosion_level = 0.8;
      volcanic_activity = 0.1;
    };
  ]

let axis_range size =
  let half = size / 2 in
  let start, end_ =
    if size mod 2 = 0 then
      (-half, half - 1)
    else
      (-half, half)
  in
  List.init (end_ - start + 1) (fun i -> start + i)

(* Initialize noise generators with different seeds for each feature *)
let create_generators seed =
  let base_noise = PerlinNoise.create ~seed () in
  let temp_noise = PerlinNoise.create ~seed:(seed + 1) () in
  let moisture_noise = PerlinNoise.create ~seed:(seed + 2) () in
  let biome_noise = PerlinNoise.create ~seed:(seed + 3) () in
  (base_noise, temp_noise, moisture_noise, biome_noise)

(* Enhanced climate generation considering geological history *)
let generate_climate params noise_gens geological_eras (x, y, z) =
  let elevation_noise, temp_noise, moisture_noise, biome_noise = noise_gens in

  (* Apply each geological era's effects *)
  let base_elevation = ref 0.0 in
  List.iter
    (fun era ->
      let era_noise = PerlinNoise.create ~seed:era.era_seed () in
      let tectonic_effect =
        PerlinNoise.octave_noise era_noise
          (float_of_int x /. params.elevation_scale)
          (float_of_int y /. params.elevation_scale)
          (float_of_int z /. params.elevation_scale *. era.tectonic_activity)
      in
      let volcanic_effect =
        if era.volcanic_activity > 0.5 then
          let volcano_centers =
            PerlinNoise.create ~seed:(era.era_seed + 1) ()
          in
          let dist =
            PerlinNoise.octave_noise volcano_centers
              (float_of_int x /. (params.elevation_scale *. 2.0))
              (float_of_int y /. (params.elevation_scale *. 2.0))
              0.0
          in
          if dist > 0.7 then
            era.volcanic_activity
          else
            0.0
        else
          0.0
      in
      base_elevation :=
        !base_elevation
        +. (tectonic_effect *. era.tectonic_activity)
        +. (volcanic_effect *. 0.3))
    geological_eras;

  (* Apply erosion *)
  let erosion_factor =
    List.fold_left (fun acc era -> acc +. era.erosion_level) 0.0 geological_eras
    /. float_of_int (List.length geological_eras)
  in

  let eroded_elevation =
    let slope =
      abs_float
        (!base_elevation
        -. PerlinNoise.octave_noise elevation_noise
             (float_of_int (x + 1) /. params.elevation_scale)
             (float_of_int y /. params.elevation_scale)
             (float_of_int z /. params.elevation_scale))
    in
    if slope > 0.3 then
      !base_elevation -. (slope *. erosion_factor *. 0.5)
    else
      !base_elevation
  in

  (* Generate microclimate *)
  let microclimate =
    {
      local_temp_mod =
        PerlinNoise.noise3d temp_noise
          (float_of_int x /. (params.temperature_scale *. 0.1))
          (float_of_int y /. (params.temperature_scale *. 0.1))
          (float_of_int z /. (params.temperature_scale *. 0.1))
        *. 0.2;
      local_moisture_mod =
        PerlinNoise.noise3d moisture_noise
          (float_of_int x /. (params.moisture_scale *. 0.1))
          (float_of_int y /. (params.moisture_scale *. 0.1))
          (float_of_int z /. (params.moisture_scale *. 0.1))
        *. 0.2;
      wind_effect =
        PerlinNoise.octave_noise biome_noise
          (float_of_int x /. (params.elevation_scale *. 2.0))
          (float_of_int y /. (params.elevation_scale *. 2.0))
          0.0;
      shadow_effect =
        (if eroded_elevation > 0.5 then
           0.2 *. (eroded_elevation -. 0.5)
         else
           0.0);
    }
  in

  (* Calculate final climate values *)
  let elevation = max (-1.0) (min 1.0 eroded_elevation) in

  let base_temp =
    PerlinNoise.noise3d temp_noise
      (float_of_int y /. params.temperature_scale)
      (float_of_int x /. params.temperature_scale)
      (float_of_int z /. params.temperature_scale)
  in
  let temperature =
    let temp_with_elevation = base_temp -. (Float.abs elevation *. 0.4) in
    let temp_with_micro =
      temp_with_elevation +. microclimate.local_temp_mod
      -. (microclimate.shadow_effect *. 0.3)
      +. (microclimate.wind_effect *. 0.1)
    in
    max (-1.0) (min 1.0 temp_with_micro)
  in

  let base_moisture =
    PerlinNoise.noise3d moisture_noise
      (float_of_int y /. params.moisture_scale)
      (float_of_int x /. params.moisture_scale)
      (float_of_int z /. params.moisture_scale)
  in
  let moisture =
    let moisture_with_micro =
      base_moisture +. microclimate.local_moisture_mod
      +. (microclimate.wind_effect *. 0.2)
      -. (microclimate.shadow_effect *. 0.2)
    in
    max (-1.0) (min 1.0 moisture_with_micro)
  in

  { Area.elevation; temperature; moisture }

let compute_room_type ({ elevation; temperature; moisture } : Area.climate) =
  let slope = moisture *. elevation in
  if elevation < -0.5 then
    Area.Cave
  else if elevation > 0.8 then
    if temperature > 0.7 then
      Area.Volcano
    else if moisture > 0.7 then
      Area.Forest
    else
      Area.Mountain
  else if temperature < 0.2 then
    Area.Tundra
  else if temperature > 0.7 && moisture < 0.2 then
    Area.Desert
  else if moisture > 0.8 then
    if slope > 0.3 then
      Area.Jungle
    else if temperature > 0.6 then
      Area.Swamp
    else
      Area.Lake
  else if elevation > 0.3 then
    if slope < -0.2 then
      Area.Canyon
    else if moisture > 0.5 then
      Area.Forest
    else
      Area.Mountain
  else if moisture > 0.5 then
    Area.Forest
  else
    Area.Lake

(* Generate biome transitions *)
let get_biome_transition climate =
  let primary_biome = compute_room_type climate in
  let temp_shift = climate.temperature +. 0.1 in
  let moisture_shift = climate.moisture -. 0.1 in
  let shifted_climate =
    { climate with temperature = temp_shift; moisture = moisture_shift }
  in
  let secondary_biome = compute_room_type shifted_climate in
  if primary_biome = secondary_biome then
    None
  else
    let blend = abs_float temp_shift +. (abs_float moisture_shift /. 2.0) in
    Some { primary_biome; secondary_biome; blend_factor = blend }

(* Enhanced room type description generation *)
let get_room_type_description room_type transition =
  let base_desc =
    match room_type with
    | Area.Cave ->
        "You are in a dark cave. The rough stone walls echo with distant \
         sounds."
    | Area.Forest -> "You are in a forest. Trees of varying sizes surround you."
    | Area.Mountain ->
        "You are on a mountainous outcropping. The winds whip around you."
    | Area.Swamp ->
        "You are in a swampy area. The ground is soft and wet beneath your \
         feet."
    | Area.Desert ->
        "You are in a desert region. Sand stretches as far as you can see."
    | Area.Tundra ->
        "You are in a frozen wasteland. The ground is hard and icy."
    | Area.Lake ->
        "You are near a body of water. The air is heavy with moisture."
    | Area.Canyon -> "You are in a canyon. Steep walls rise around you."
    | Area.Volcano ->
        "You are in a volcanic crater. The air is hot and filled with ash."
    | Area.Jungle ->
        "You are in a dense jungle. The air is thick with humidity and the \
         sounds of wildlife fill the air."
  in
  match transition with
  | None -> base_desc
  | Some t ->
      let transition_desc =
        match t.secondary_biome with
        | Area.Desert when t.blend_factor > 0.7 ->
            "The ground gradually becomes more sandy."
        | Area.Forest when t.blend_factor > 0.7 ->
            "You can see trees beginning to dot the landscape."
        | Area.Mountain when t.blend_factor > 0.7 ->
            "The terrain becomes increasingly rocky and elevated."
        | Area.Swamp when t.blend_factor > 0.7 ->
            "The ground gradually becomes softer and wetter."
        | Area.Tundra when t.blend_factor > 0.7 ->
            "The air grows noticeably colder."
        | Area.Jungle when t.blend_factor > 0.7 ->
            "The vegetation becomes increasingly dense and tropical."
        | _ -> ""
      in
      if transition_desc = "" then
        base_desc
      else
        base_desc ^ " " ^ transition_desc

let get_room_name (climate : Area.climate) (z : int) =
  match z with
  | z when z > 0 ->
      if climate.elevation > sky_elevation then
        "Floating Island"
      else if climate.temperature < frozen_temperature then
        "Frozen Cloud Platform"
      else
        "Cloud Platform"
  | 0 -> (
      let room_type = compute_room_type climate in
      match room_type with
      | Area.Cave -> "Cave"
      | Area.Forest -> "Forest"
      | Area.Mountain -> "Mountain Peak"
      | Area.Swamp -> "Swamp"
      | Area.Desert -> "Desert"
      | Area.Tundra -> "Frozen Wastes"
      | Area.Lake -> "Lakeshore"
      | Area.Canyon -> "Canyon"
      | Area.Volcano -> "Volcanic Crater"
      | Area.Jungle -> "Dense Jungle")
  | _ ->
      let depth_influence = float_of_int (-z) *. 0.2 in
      if depth_influence > 0.8 then
        "Deep Abyss"
      else if climate.moisture > 0.7 -. depth_influence then
        "Subterranean Lake"
      else if climate.temperature > 0.6 +. depth_influence then
        "Lava Cavern"
      else
        "Underground Tunnel"

(* Generate coordinates for the world grid *)
let generate_coordinates params =
  let coords = ref [] in
  let x_coords = axis_range params.width in
  let y_coords = axis_range params.height in
  let z_coords = axis_range params.depth in

  List.iter
    (fun z ->
      List.iter
        (fun y ->
          List.iter
            (fun x ->
              if not (x = 0 && y = 0 && z = 0) then
                coords := (x, y, z) :: !coords)
            x_coords)
        y_coords)
    z_coords;
  !coords

(* Split coordinates into batches *)
let create_batches batch_size coords =
  let rec split_batches acc current_batch remaining =
    match remaining with
    | [] ->
        if current_batch = [] then
          acc
        else
          current_batch :: acc
    | coord :: rest ->
        if List.length current_batch >= batch_size then
          split_batches (current_batch :: acc) [ coord ] rest
        else
          split_batches acc (coord :: current_batch) rest
  in
  split_batches [] [] coords |> List.rev

(* Create an area at the given coordinates with generated climate *)
let create_area_at_coord params noise_gens geological_eras coord_map (x, y, z) =
  let climate = generate_climate params noise_gens geological_eras (x, y, z) in
  let transition = get_biome_transition climate in
  let room_type = compute_room_type climate in
  let name = get_room_name climate z in
  let description = get_room_type_description room_type transition in
  let* result =
    Area.create_with_climate ~name ~description ~x ~y ~z ~climate ()
  in
  match result with
  | Ok area ->
      Hashtbl.add coord_map (x, y, z) area.id;
      Lwt.return_unit
  | Error _ -> Lwt.return_unit

(* Process a single batch of areas *)
let process_area_batch params noise_gens geological_eras batch =
  let coord_map = Hashtbl.create (List.length batch) in
  let* () =
    Lwt_list.iter_s
      (fun (x, y, z) ->
        let* () =
          create_area_at_coord params noise_gens geological_eras coord_map
            (x, y, z)
        in
        Lwt.return_unit)
      batch
  in
  Lwt.return coord_map

let generate_and_create_world (params : world_params) (client : Client.t) =
  let noise_gens = create_generators params.seed in
  let geological_eras = geological_history params.seed in

  (* Generate coordinates and split into batches *)
  let all_coords = generate_coordinates params in
  let area_batches = create_batches batch_size all_coords in

  let* () = Client_handler.send_success client "World generation started" in

  (* Process area batches sequentially *)
  let* area_maps =
    Lwt_list.mapi_s
      (fun i batch ->
        let* () =
          Client_handler.send_success client
            (Printf.sprintf "Processing areas batch %d of %d" (i + 1)
               (List.length area_batches))
        in
        process_area_batch params noise_gens geological_eras batch)
      area_batches
  in

  (* Combine all area maps *)
  let final_map =
    Hashtbl.create (params.width * params.height * params.depth)
  in
  List.iter
    (fun batch_map ->
      Hashtbl.iter (fun coords id -> Hashtbl.add final_map coords id) batch_map)
    area_maps;

  (* Add starting area *)
  let* () =
    match%lwt Area.find_by_id "00000000-0000-0000-0000-000000000000" with
    | Ok area ->
        Hashtbl.add final_map (0, 0, 0) area.id;
        Lwt.return_unit
    | Error _ -> Lwt.return_unit
  in

  (* Create exits in batches *)
  let* () = Client_handler.send_success client "Creating exits" in

  (* Build list of all needed exits first *)
  let collect_exits_for_coords (x, y, z) =
    let area_id = Hashtbl.find final_map (x, y, z) in
    let directions =
      [
        (Area.North, (0, -1, 0));
        (Area.South, (0, 1, 0));
        (Area.East, (1, 0, 0));
        (Area.West, (-1, 0, 0));
        (Area.Up, (0, 0, 1));
        (Area.Down, (0, 0, -1));
      ]
    in
    List.fold_left
      (fun acc (dir, (dx, dy, dz)) ->
        let tx, ty, tz = (x + dx, y + dy, z + dz) in
        match Hashtbl.find_opt final_map (tx, ty, tz) with
        | Some target_id ->
            (* Only create "forward" exits - the query will handle bidirectional *)
            (area_id, target_id, dir) :: acc
        | None -> acc)
      [] directions
  in

  let coords_list = Hashtbl.fold (fun k _ acc -> k :: acc) final_map [] in
  let all_exits = List.concat_map collect_exits_for_coords coords_list in

  (* Create larger batches for exits *)
  let exit_batch_size = 1000 in
  let exit_batches = create_batches exit_batch_size all_exits in

  (* Create exits in larger batches with a single transaction per batch *)
  let create_exit_batch exits =
    let db_operation (module Db : Caqti_lwt.CONNECTION) =
      let* () =
        Lwt_list.iter_s
          (fun (from_id, to_id, dir) ->
            let* _ =
              Db.exec Area.Q.insert_exit
                {
                  from_area_id = from_id;
                  to_area_id = to_id;
                  direction = dir;
                  description = None;
                  hidden = false;
                  locked = false;
                }
            in
            let* _ =
              Db.exec Area.Q.insert_exit
                {
                  from_area_id = to_id;
                  to_area_id = from_id;
                  direction = Area.opposite_direction dir;
                  description = None;
                  hidden = false;
                  locked = false;
                }
            in
            Lwt.return_unit)
          exits
      in
      Lwt_result.return ()
    in
    Infra.Database.Pool.use db_operation
  in

  let* () =
    Lwt_list.iteri_s
      (fun i batch ->
        let* () =
          Client_handler.send_success client
            (Printf.sprintf "Creating exits batch %d of %d" (i + 1)
               (List.length exit_batches))
        in
        match%lwt create_exit_batch batch with
        | Ok () -> Lwt.return_unit
        | Error _ -> Lwt.return_unit)
      exit_batches
  in

  let* () = Client_handler.send_success client "World generation complete" in
  Lwt.return final_map
