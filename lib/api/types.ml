type character = {
  id : string;
  name : string;
} [@@deriving yojson]

let character_of_model (character_model : Qed_domain.Character.t) : character =
  {
    id = character_model.id;
    name = character_model.name;
  }

type exit = {
  direction : string;
} [@@deriving yojson]

type area = {
  name : string;
  description : string;
  exits : exit list;
} [@@deriving yojson]

let exit_of_model (exit_model : Qed_domain.Area.exit) : exit =
  {
    direction = Qed_domain.Area.direction_to_string exit_model.direction;
  }

let area_of_model (area_model : Qed_domain.Area.t) (exits : Qed_domain.Area.exit list) : area =
  {
    name = area_model.name;
    description = area_model.description;
    exits = List.map exit_of_model exits;
  }
