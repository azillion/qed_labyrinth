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

let of_character (_character: Character.t) =
  (* Convert game character data to status frame format *)
  {
    health = 100;  (* Example values - replace with real data *)
    max_health = 100;
    mana = 50;
    max_mana = 50;
    level = 1;
    experience = 0;
    time_of_day = Utils.calculate_time_of_day ();
  }
