open Core

(* Create our test world *)
let kitchen =
  Space.create "Kitchen"
    "A warm and inviting kitchen with copper pots hanging from the ceiling. \
     The smell of fresh bread lingers in the air."
    []

let living_room =
  Space.create "Living Room"
    "A cozy space with comfortable furniture. Sunlight streams through large \
     windows."
    []

let garden =
  Space.create "Garden"
    "A peaceful garden with flowering plants and a small fountain. Birds can \
     be heard chirping nearby."
    []

(* Connect the spaces *)
let spaces =
  let kitchen =
    {
      kitchen with
      connections = [ { target = living_room.id; direction = "east" } ];
    }
  in
  let living_room =
    {
      living_room with
      connections =
        [
          { target = kitchen.id; direction = "west" };
          { target = garden.id; direction = "south" };
        ];
    }
  in
  let garden =
    {
      garden with
      connections = [ { target = living_room.id; direction = "north" } ];
    }
  in
  [ kitchen; living_room; garden ]

let () = Game.start_game kitchen.id spaces |> ignore
