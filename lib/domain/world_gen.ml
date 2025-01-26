open Utils

let uuid seed = Uuidm.v4_gen seed ()

let axis_range size =
  let half = size / 2 in
  let start, end_ =
    if size mod 2 = 0 then
      (-half, half - 1)
    else
      (-half, half)
  in
  let rec range a b =
    if a > b then
      []
    else
      a :: range (a + 1) b
  in
  range start end_

(* World generation parameters *)
type world_params = {
  seed : int;
  width : int;
  height : int;
  depth : int;
  elevation_scale : float;
  temperature_scale : float;
  moisture_scale : float;
}

let get_room_name (climate : Area.climate) z =
  match z with
  | z when z > 0 ->
      (* Sky layers *)
      if climate.elevation > 0.7 then
        "Floating Island"
      else if climate.temperature < -0.3 then
        "Frozen Cloud Platform"
      else
        "Cloud Platform"
  | 0 -> (
      (* Ground layer *)
      match
        Area.get_room_type
          {
            id = "";
            name = "";
            description = "";
            x = 0;
            y = 0;
            z = 0;
            elevation = Some climate.elevation;
            temperature = Some climate.temperature;
            moisture = Some climate.moisture;
          }
      with
      | Some Area.Cave -> "Cave"
      | Some Area.Forest -> "Forest"
      | Some Area.Mountain -> "Mountain Peak"
      | Some Area.Swamp -> "Swamp"
      | Some Area.Desert -> "Desert"
      | Some Area.Tundra -> "Frozen Wastes"
      | Some Area.Lake -> "Lakeshore"
      | Some Area.Canyon -> "Canyon"
      | None -> "Unknown Area")
  | _ ->
      (* Underground *)
      if climate.moisture > 0.8 then
        "Subterranean Lake"
      else if climate.temperature > 0.7 then
        "Lava Cavern"
      else if climate.elevation < -0.5 then
        "Deep Abyss"
      else
        "Underground Tunnel"

(* Initialize noise generators with different seeds for each feature *)
let create_generators seed =
  let base_noise = PerlinNoise.create ~seed () in
  let temp_noise = PerlinNoise.create ~seed:(seed + 1) () in
  let moisture_noise = PerlinNoise.create ~seed:(seed + 2) () in
  (base_noise, temp_noise, moisture_noise)

(* Generate climate for a specific coordinate *)
let generate_climate params noise_gens (x, y, z) : Area.climate =
  let elevation_noise, temp_noise, moisture_noise = noise_gens in
  (* Convert coordinates to floats for noise generation *)
  let fx = float_of_int x in
  let fy = float_of_int y in
  let fz = float_of_int z in

  (* Scale coordinates using parameters *)
  let scaled_x = fy /. params.elevation_scale in
  (* Note: Swapped X/Y *)
  let scaled_y = fx /. params.elevation_scale in
  (* for better horizontal spread *)
  let scaled_z = fz /. (params.elevation_scale *. 0.5) in

  (* Vertical compression *)

  (* Generate base elevation with 3D noise *)
  let elevation =
    (PerlinNoise.octave_noise elevation_noise scaled_x scaled_y scaled_z *. 2.0)
    -. 1.0
  in

  (* Temperature calculation with altitude effect *)
  let base_temp =
    PerlinNoise.noise3d temp_noise
      (fy /. params.temperature_scale)
      (fx /. params.temperature_scale)
      (fz /. params.temperature_scale)
  in
  let temp_with_elevation = base_temp -. (Float.abs elevation *. 0.4) in
  let temperature = max (-1.0) (min 1.0 temp_with_elevation) in

  (* Allow below zero *)

  (* Moisture calculation with 3D noise *)
  let base_moisture =
    PerlinNoise.noise3d moisture_noise
      (fy /. params.moisture_scale)
      (fx /. params.moisture_scale)
      (fz /. params.moisture_scale)
  in
  let moisture = max (-1.0) (min 1.0 base_moisture) in

  (* Allow negative moisture *)
  { elevation; temperature; moisture }

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

(* Create an area at the given coordinates with generated climate *)
let create_area_at_coord params noise_gens coord_map (x, y, z) =
  let climate = generate_climate params noise_gens (x, y, z) in
  let name = get_room_name climate z in
  let%lwt result =
    Area.create_with_climate ~name
      ~description:
        (Area.get_climate_description
           {
             id = "";
             name = "";
             description = "";
             x;
             y;
             z;
             elevation = Some climate.elevation;
             temperature = Some climate.temperature;
             moisture = Some climate.moisture;
           })
      ~x ~y ~z ~climate ()
  in
  match result with
  | Ok area ->
      Hashtbl.add coord_map (x, y, z) area.id;
      Lwt.return_unit
  | Error _ -> Lwt.return_unit

let generate_and_create_world params =
  let noise_gens = create_generators params.seed in
  let coord_map =
    Hashtbl.create (params.width * params.height * params.depth)
  in

  (* Generate all areas except starting area *)
  let%lwt () =
    generate_coordinates params
    |> Lwt_list.iter_s (create_area_at_coord params noise_gens coord_map)
  in

  (* Add starting area to coord_map *)
  let%lwt () =
    match%lwt Area.find_by_id "00000000-0000-0000-0000-000000000000" with
    | Ok area ->
        Hashtbl.add coord_map (0, 0, 0) area.id;
        Lwt.return_unit
    | Error _ -> Lwt.return_unit
  in

  (* Create bidirectional exits between adjacent areas *)
  let create_exit ~from_id ~to_id ~dir =
    let%lwt _ =
      Area.create_exit ~from_area_id:from_id ~to_area_id:to_id ~direction:dir
        ~description:None ~hidden:false ~locked:false
    in
    Area.create_exit ~from_area_id:to_id ~to_area_id:from_id
      ~direction:(Area.opposite_direction dir)
      ~description:None ~hidden:false ~locked:false
  in

  let%lwt () =
    Hashtbl.fold
      (fun (x, y, z) area_id acc ->
        let directions =
          [
            (Area.North, (0, -1, 0));
            (* Decrease Y *)
            (Area.South, (0, 1, 0));
            (* Increase Y *)
            (Area.East, (1, 0, 0));
            (* Increase X *)
            (Area.West, (-1, 0, 0));
            (* Decrease X *)
            (Area.Up, (0, 0, 1));
            (* Increase Z *)
            (Area.Down, (0, 0, -1));
            (* Decrease Z *)
          ]
        in
        let%lwt () = acc in
        Lwt_list.iter_s
          (fun (dir, (dx, dy, dz)) ->
            let tx, ty, tz = (x + dx, y + dy, z + dz) in
            match Hashtbl.find_opt coord_map (tx, ty, tz) with
            | Some target_id -> (
                let%lwt result =
                  create_exit ~from_id:area_id ~to_id:target_id ~dir
                in
                match result with
                | Ok _ -> Lwt.return_unit
                | Error _ -> Lwt.return_unit)
            | None -> Lwt.return_unit)
          directions)
      coord_map Lwt.return_unit
  in

  Lwt.return coord_map
