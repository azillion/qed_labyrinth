
let calculate_time_of_day = fun () ->
  let current_time = Unix.gettimeofday () in
  let hours = int_of_float (current_time *. 24.0) in
  if hours < 6 then "night"
  else if hours < 12 then "morning"
  else if hours < 18 then "afternoon"
  else "evening"

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
  time_of_day = calculate_time_of_day ();
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
    time_of_day = calculate_time_of_day ();
  }
