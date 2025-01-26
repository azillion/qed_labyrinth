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

(* Generate coordinates for the world grid *)
let generate_coordinates params =
  let coords = ref [] in
  for z = 0 to params.depth - 1 do
    for y = 0 to params.height - 1 do
      for x = 0 to params.width - 1 do
        if not (x = 0 && y = 0 && z = 0) then
          coords := (x, y, z) :: !coords
      done
    done
  done;
  !coords

(* Create an area at the given coordinates with generated climate *)
let create_area_at_coord params noise_gens coord_map (x, y, z) =
  let climate = generate_climate params noise_gens (x, y, z) in
  let name = get_room_name climate in
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
      Area.create_exit ~from_area_id:from_id ~to_area_id:to_id
        ~direction:dir ~description:None ~hidden:false ~locked:false
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
            (Area.North, (0, -1, 0));   (* Decrease Y *)
            (Area.South, (0, 1, 0));    (* Increase Y *)
            (Area.East, (1, 0, 0));     (* Increase X *)
            (Area.West, (-1, 0, 0));    (* Decrease X *)
            (Area.Up, (0, 0, 1));       (* Increase Z *)
            (Area.Down, (0, 0, -1));    (* Decrease Z *)
          ]
        in
        let%lwt () = acc in
        Lwt_list.iter_s
          (fun (dir, (dx, dy, dz)) ->
            let tx, ty, tz = (x + dx, y + dy, z + dz) in
            match Hashtbl.find_opt coord_map (tx, ty, tz) with
            | Some target_id ->
                let%lwt result = create_exit ~from_id:area_id ~to_id:target_id ~dir in
                begin match result with
                | Ok _ -> Lwt.return_unit
                | Error _ -> Lwt.return_unit
                end
            | None -> Lwt.return_unit)
          directions)
      coord_map Lwt.return_unit
  in

  Lwt.return coord_map
