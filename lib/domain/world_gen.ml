open Utils

let uuid seed = Uuidm.v4_gen seed ()

module WorldGen = struct
  (* Room environmental characteristics *)

  type room = {
    id: string;
    x: int;
    y: int;
    z: int;
    climate: Area.climate;
    room_type: room_type;
    exits: exit list;
  }
  and exit = {
    direction: direction;
    target_id: string;
  }
  and direction = North | South | East | West | Up | Down
  and room_type =
    | Cave
    | Forest
    | Mountain
    | Swamp
    | Desert
    | Tundra
    | Lake
    | Canyon

  (* World generation parameters *)
  type world_params = {
    seed: int;
    width: int;
    height: int;
    depth: int;
    elevation_scale: float;
    temperature_scale: float;
    moisture_scale: float;
  }

  (* Initialize noise generators with different seeds for each feature *)
  let create_generators seed =
    let base_noise = PerlinNoise.create ~seed () in
    let temp_noise = PerlinNoise.create ~seed:(seed + 1) () in
    let moisture_noise = PerlinNoise.create ~seed:(seed + 2) () in
    (base_noise, temp_noise, moisture_noise)

  (* Generate climate for a specific coordinate *)
  let generate_climate params noise_gens (x, y, z) : Area.climate =
    let (elevation_noise, temp_noise, moisture_noise) = noise_gens in
    let scaled_x = float_of_int y /. params.elevation_scale in
    let scaled_y = float_of_int x /. params.elevation_scale in
    let scaled_z = float_of_int z /. params.elevation_scale in

    (* Generate base elevation *)
    let elevation = (PerlinNoise.octave_noise elevation_noise 
      scaled_x scaled_y scaled_z) *. 2.0 -. 1.0 in

    (* Temperature decreases with elevation and varies horizontally *)
    let base_temp = PerlinNoise.noise2d temp_noise 
      (float_of_int y /. params.temperature_scale)
      (float_of_int x /. params.temperature_scale) in
    let temp_with_elevation = base_temp -. (max 0.0 elevation) *. 0.3 in
    let temperature = max 0.0 (min 1.0 temp_with_elevation) in

    (* Moisture varies with elevation and temperature *)
    let base_moisture = PerlinNoise.noise2d moisture_noise
      (float_of_int y /. params.moisture_scale)
      (float_of_int x /. params.moisture_scale) in
    let moisture = max 0.0 (min 1.0 base_moisture) in

    { elevation; temperature; moisture }

  (* Determine room type based on climate *)
  let determine_room_type (climate : Area.climate) =
    match climate with
    | { elevation = e; temperature = t; moisture = m } ->
        if e < -0.5 then Cave
        else if e > 0.6 then Mountain
        else if t < 0.2 then Tundra
        else if t > 0.7 && m < 0.2 then Desert
        else if m > 0.7 then
          if t > 0.6 then Swamp else Lake
        else if e > 0.3 then
          if m > 0.4 then Forest else Canyon
        else Forest

  (* Generate a single room *)
  let generate_room params noise_gens x y z =
    let climate = generate_climate params noise_gens (x, y, z) in
    let room_type = determine_room_type climate in
    let rng = Random.State.make [|params.seed|] in
    let id = Uuidm.to_string (uuid rng) in
    { id; x; y; z; climate; room_type; exits = [] }

  (* Connect rooms with appropriate exits *)
  let connect_rooms rooms =
    let room_map = Hashtbl.create (List.length rooms) in
    List.iter (fun room -> Hashtbl.add room_map (room.x, room.y, room.z) room) rooms;
    
    let check_and_connect room dx dy dz direction =
      let target_x = room.x + dx in
      let target_y = room.y + dy in
      let target_z = room.z + dz in
      match Hashtbl.find_opt room_map (target_x, target_y, target_z) with
      | Some target -> 
          let exit = { direction; target_id = target.id } in
          { room with exits = exit :: room.exits }
      | None -> room
    in

    List.map (fun room ->
      let room = check_and_connect room 1 0 0 East in
      let room = check_and_connect room (-1) 0 0 West in
      let room = check_and_connect room 0 1 0 North in
      let room = check_and_connect room 0 (-1) 0 South in
      let room = check_and_connect room 0 0 1 Up in
      let room = check_and_connect room 0 0 (-1) Down in
      room
    ) rooms

  (* Generate entire world *)
  let generate_world params =
    let noise_gens = create_generators params.seed in
    let rooms = ref [] in
    
    (* Generate all rooms *)
    for x = 0 to params.width - 1 do
      for y = 0 to params.height - 1 do
        for z = 0 to params.depth - 1 do
          if x = 0 && y = 0 && z = 0 then
            Stdio.printf "Generating starting room\n"
          else
            let room = generate_room params noise_gens x y z in
            rooms := room :: !rooms
        done
      done
    done;

    (* Connect rooms and return final world *)
    connect_rooms !rooms

  (* Helper functions for describing rooms *)
  let climate_description (climate : Area.climate) =
    let elevation_desc =
      if climate.elevation < -0.5 then "deep underground"
      else if climate.elevation < -0.2 then "underground"
      else if climate.elevation < 0.2 then "at ground level"
      else if climate.elevation < 0.6 then "elevated"
      else "high up" in
    
    let temp_desc =
      if climate.temperature < 0.2 then "freezing"
      else if climate.temperature < 0.4 then "cold"
      else if climate.temperature < 0.6 then "mild"
      else if climate.temperature < 0.8 then "warm"
      else "hot" in
    
    let moisture_desc =
      if climate.moisture < 0.2 then "arid"
      else if climate.moisture < 0.4 then "dry"
      else if climate.moisture < 0.6 then "moderate humidity"
      else if climate.moisture < 0.8 then "humid"
      else "waterlogged" in
    
    Printf.sprintf "%s, %s, and %s" elevation_desc temp_desc moisture_desc
end

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