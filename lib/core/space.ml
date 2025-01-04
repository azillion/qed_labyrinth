type id = string [@@deriving yojson]
type connection = { target : id; direction : string } [@@deriving yojson]

type t = {
  id : id;
  name : string;
  description : string;
  connections : connection list;
}
[@@deriving yojson]

(* Create deterministic ID from name *)
let make_id name =
  let ctx = Digestif.SHA1.init () in
  let ctx = Digestif.SHA1.feed_string ctx name in
  let hash = Digestif.SHA1.get ctx in
  String.sub (Digestif.SHA1.to_hex hash) 0 32

let create name description connections =
  { id = make_id name; name; description; connections }

let get_space_by_name name spaces =
  try
    let space = List.find (fun space -> space.name = name) spaces in
    Some space
  with
  | Not_found -> None

let test_world =
  let kitchen = create "Kitchen" "A clean and organized space." [] in
  let living_room = create "Living Room" "A cozy space with comfortable furniture." [] in
  let garden = create "Garden" "A peaceful outdoor space." [] in
  [
    { kitchen with connections = [ { target = living_room.id; direction = "east" } ] };
    { living_room with connections = [ { target = kitchen.id; direction = "west" } ] };
    { garden with connections = [ { target = living_room.id; direction = "north" } ] };
  ]
