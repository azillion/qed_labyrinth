module CharacterComponent = struct
  type t = {
    entity_id: string;
    user_id: string;  (* Links character to the owning user *)
  } [@@deriving yojson]

  let table_name = "characters"
end

module CharacterPositionComponent = struct
  type t = {
    entity_id: string;
    area_id: string;  (* entity ID of the area where the character is located *)
  } [@@deriving yojson]

  let table_name = "character_positions"
end

module DescriptionComponent = struct
  type t = {
    entity_id: string;
    name: string;
    description: string option;
  } [@@deriving yojson]

  let table_name = "descriptions"
end
