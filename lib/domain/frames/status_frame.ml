type t = {
  health: int;
  max_health: int;
  mana: int;
  max_mana: int;
  level: int;
  experience: int;
  time_of_day: string;
}

let empty = {
  health = 0;
  max_health = 0;
  mana = 0;
  max_mana = 0;
  level = 1;
  experience = 0;
  time_of_day = Utils.calculate_time_of_day ();
}

let of_character (character: Character.t) =
  (* Convert game character data to status frame format *)
  {
    health = character.health;
    max_health = character.max_health;
    mana = character.mana;
    max_mana = character.max_mana;
    level = character.level;
    experience = character.experience;
    time_of_day = Utils.calculate_time_of_day ();
  }
