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

let test_world =
  [
    {
      id = "kitchen";
      name = "Kitchen";
      description = "A clean and organized space.";
      connections = [ { target = "living_room"; direction = "east" } ];
    };
    {
      id = "living_room";
      name = "Living Room";
      description = "A cozy space with comfortable furniture.";
      connections =
        [
          { target = "kitchen"; direction = "west" };
          { target = "garden"; direction = "south" };
        ];
    };
    {
      id = "garden";
      name = "Garden";
      description = "A peaceful outdoor space.";
      connections = [ { target = "living_room"; direction = "north" } ];
    };
  ]
