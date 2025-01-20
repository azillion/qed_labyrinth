type character = {
  id : string;
  name : string;
} [@@deriving yojson]

let character_of_model (character_model : Qed_domain.Character.t) : character =
  {
    id = character_model.id;
    name = character_model.name;
  }
