open Utils

let uuid seed = Uuidm.v4_gen seed ()

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

let get_room_name (climate : Area.climate) =
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
  | None -> "Unknown Area"

(* Initialize noise generators with different seeds for each feature *)
let create_generators seed =
  let base_noise = PerlinNoise.create ~seed () in
  let temp_noise = PerlinNoise.create ~seed:(seed + 1) () in
  let moisture_noise = PerlinNoise.create ~seed:(seed + 2) () in
  (base_noise, temp_noise, moisture_noise)

(* Generate climate for a specific coordinate *)
let generate_climate params noise_gens (x, y, z) : Area.climate =
  let elevation_noise, temp_noise, moisture_noise = noise_gens in
  let scaled_x = float_of_int y /. params.elevation_scale in
  let scaled_y = float_of_int x /. params.elevation_scale in
  let scaled_z = float_of_int z /. params.elevation_scale in

  (* Generate base elevation *)
  let elevation =
    (PerlinNoise.octave_noise elevation_noise scaled_x scaled_y scaled_z *. 2.0)
    -. 1.0
  in

  (* Temperature decreases with elevation and varies horizontally *)
  let base_temp =
    PerlinNoise.noise2d temp_noise
      (float_of_int y /. params.temperature_scale)
      (float_of_int x /. params.temperature_scale)
  in
  let temp_with_elevation = base_temp -. (max 0.0 elevation *. 0.3) in
  let temperature = max 0.0 (min 1.0 temp_with_elevation) in

  (* Moisture varies with elevation and temperature *)
  let base_moisture =
    PerlinNoise.noise2d moisture_noise
      (float_of_int y /. params.moisture_scale)
      (float_of_int x /. params.moisture_scale)
  in
  let moisture = max 0.0 (min 1.0 base_moisture) in

  { elevation; temperature; moisture }

(* Example usage:
   let params = {
     seed = 42;
     width = 10;
     height = 10;
     depth = 5;
     elevation_scale = 15.0;
     temperature_scale = 20.0;
     moisture_scale = 18.0;
   } in
   let world = WorldGen.generate_world params in
   ...
*)

let generate_and_create_world params =
  let noise_gens = create_generators params.seed in
  let coord_map =
    Hashtbl.create (params.width * params.height * params.depth)
  in

  let rec create_areas x y z =
    if z >= params.depth then
      Lwt.return_unit
    else if y >= params.height then
      create_areas x 0 (z + 1)
    else if x >= params.width then
      create_areas 0 (y + 1) z
    else if x = 0 && y = 0 && z = 0 then
      (* Skip starting area coordinates *)
      create_areas (x + 1) y z
    else
      let climate = generate_climate params noise_gens (x, y, z) in
      let name = get_room_name climate in
      match%lwt
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
      with
      | Ok area ->
          Hashtbl.add coord_map (x, y, z) area.id;
          create_areas (x + 1) y z
      | Error _ -> create_areas (x + 1) y z
  in

  let%lwt () = create_areas 0 0 0 in

  (* Add starting area to coord_map *)
  let%lwt () =
    match%lwt Area.find_by_id "00000000-0000-0000-0000-000000000000" with
    | Ok area ->
        Hashtbl.add coord_map (0, 0, 0) area.id;
        Lwt.return_unit
    | Error _ -> Lwt.return_unit
  in

  (* Create exits between areas *)
  let%lwt () =
    Hashtbl.fold
      (fun (x, y, z) area_id acc ->
        let directions =
          [
            (Area.North, (0, 0, 1));
            (Area.South, (0, 0, -1));
            (Area.East, (1, 0, 0));
            (Area.West, (-1, 0, 0));
            (Area.Up, (0, 1, 0));
            (Area.Down, (0, -1, 0));
          ]
        in
        let%lwt () = acc in
        Lwt_list.iter_s
          (fun (dir, (dx, dy, dz)) ->
            let tx = x + dx in
            let ty = y + dy in
            let tz = z + dz in
            match Hashtbl.find_opt coord_map (tx, ty, tz) with
            | Some target_id ->
                let%lwt _ =
                  Area.create_exit ~from_area_id:area_id ~to_area_id:target_id
                    ~direction:dir ~description:None ~hidden:false ~locked:false
                in
                let%lwt _ =
                  Area.create_exit ~from_area_id:target_id ~to_area_id:area_id
                    ~direction:(Area.opposite_direction dir)
                    ~description:None ~hidden:false ~locked:false
                in
                Lwt.return_unit
            | None -> Lwt.return_unit)
          directions)
      coord_map Lwt.return_unit
  in

  Lwt.return coord_map
