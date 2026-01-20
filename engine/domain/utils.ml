

(* let broadcast_area_update (state : State.t) (area_id : string) =
  match%lwt get_area_by_id_opt area_id with
  | None -> Lwt.return_unit
  | Some area ->
      let update = Protocol.Area { area } in
      Connection_manager.broadcast_to_room state.connection_manager area_id
        update;
      Lwt.return_unit *)

module PerlinNoise = struct
  (* Type for our permutation table *)
  type t = { perm : int array; (* 512-length permutation table *) seed : int }

  (* Helper to create a seeded random state *)
  let create_random_state seed =
    Random.init seed;
    Random.get_state ()

  (* Fisher-Yates shuffle implementation *)
  let shuffle arr seed =
    let len = Array.length arr in
    let random_state = create_random_state seed in
    for i = len - 1 downto 1 do
      let j = Random.State.int random_state (i + 1) in
      let temp = arr.(i) in
      arr.(i) <- arr.(j);
      arr.(j) <- temp
    done

  (* Initialize the noise generator with a seed *)
  let create ?(seed = Random.int max_int) () =
    (* Create initial permutation array *)
    let base_perm = Array.init 256 (fun i -> i) in
    shuffle base_perm seed;

    (* Double the permutation table to avoid overflow *)
    let perm = Array.make 512 0 in
    for i = 0 to 511 do
      perm.(i) <- base_perm.(i land 255)
    done;

    { perm; seed }

  (* Fade function to smooth interpolation: 6t^5 - 15t^4 + 10t^3 *)
  let fade t = t *. t *. t *. ((t *. ((t *. 6.0) -. 15.0)) +. 10.0)

  (* Linear interpolation *)
  let lerp t a b = a +. (t *. (b -. a))

  (* Gradient function *)
  let grad hash x y z =
    let h = hash land 15 in
    let u =
      if h < 8 then
        x
      else
        y
    in
    let v =
      if h < 4 then
        y
      else if h = 12 || h = 14 then
        x
      else
        z
    in
    let result =
      (if h land 1 = 0 then
         u
       else
         -.u)
      +.
      if h land 2 = 0 then
        v
      else
        -.v
    in
    result

  (* Core noise function *)
  let noise t x y z =
    (* Find unit cube that contains the point *)
    let xi = int_of_float (floor x) land 255 in
    let yi = int_of_float (floor y) land 255 in
    let zi = int_of_float (floor z) land 255 in

    (* Find relative x, y, z of point in cube *)
    let x = x -. floor x in
    let y = y -. floor y in
    let z = z -. floor z in

    (* Compute fade curves *)
    let u = fade x in
    let v = fade y in
    let w = fade z in

    (* Hash coordinates of cube corners *)
    let perm = t.perm in
    let a = perm.(xi) + yi in
    let aa = perm.(a) + zi in
    let ab = perm.(a + 1) + zi in
    let b = perm.(xi + 1) + yi in
    let ba = perm.(b) + zi in
    let bb = perm.(b + 1) + zi in

    (* Blend contributions from the eight corners *)
    let result =
      lerp w
        (lerp v
           (lerp u (grad perm.(aa) x y z) (grad perm.(ba) (x -. 1.0) y z))
           (lerp u
              (grad perm.(ab) x (y -. 1.0) z)
              (grad perm.(bb) (x -. 1.0) (y -. 1.0) z)))
        (lerp v
           (lerp u
              (grad perm.(aa + 1) x y (z -. 1.0))
              (grad perm.(ba + 1) (x -. 1.0) y (z -. 1.0)))
           (lerp u
              (grad perm.(ab + 1) x (y -. 1.0) (z -. 1.0))
              (grad perm.(bb + 1) (x -. 1.0) (y -. 1.0) (z -. 1.0))))
    in

    (* Normalize to [0, 1] *)
    (result +. 1.0) /. 2.0

  (* Convenience functions for 1D and 2D noise *)
  let noise1d t x = noise t x 0.0 0.0
  let noise2d t x y = noise t x y 0.0
  let noise3d = noise  (* 3D noise is just the base noise function *)

  (* Generate octaves of noise for more natural results *)
  let octave_noise t ?(octaves = 1) ?(persistence = 0.5) x y z =
    let rec sum_octaves i freq amp total max_value =
      if i >= octaves then
        total /. max_value
      else
        let current = noise t (x *. freq) (y *. freq) (z *. freq) *. amp in
        sum_octaves (i + 1) (freq *. 2.0) (amp *. persistence)
          (total +. current) (max_value +. amp)
    in
    sum_octaves 0 1.0 1.0 0.0 0.0
end

(* Example usage:
   let noise = PerlinNoise.create ~seed:42 () in
   let value = PerlinNoise.noise2d noise 0.5 0.5 in
   Printf.printf "Noise value: %f\n" value
*)

let calculate_time_of_day () =
  let localtime = Unix.localtime (Unix.time ()) in
  let hour = localtime.tm_hour in
  if hour < 6 then "night"
  else if hour < 12 then "morning"
  else if hour < 18 then "afternoon"
  else "evening"

(* Utility: remove only the first occurrence of an item ID from a list *)
let rec remove_first_item_by_id lst item_id =
  match lst with
  | [] -> []
  | hd :: tl -> if String.equal hd item_id then tl else hd :: remove_first_item_by_id tl item_id