type t = {
  entity_id: string;
  physical_power: int;
  spell_power: int;
  accuracy: int;
  evasion: int;
  armor: int;
  resolve: int;
} [@@deriving yojson]

let table_name = "bonus_stats"

let empty entity_id = {
  entity_id;
  physical_power = 0;
  spell_power = 0;
  accuracy = 0;
  evasion = 0;
  armor = 0;
  resolve = 0;
} 