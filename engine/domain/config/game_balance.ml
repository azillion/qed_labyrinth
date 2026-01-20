let xp_for_level level =
  let base_xp = 100.0 in
  let factor = 1.2 in
  Float.to_int (base_xp *. (factor ** float_of_int (level - 1)))

let power_budget_for_level level =
  match level with
  | 1 -> 5
  | 2 -> 8
  | 3 -> 11
  | 4 -> 13
  | 5 -> 15
  | _ -> 15 + ((level - 5) * 2)

let ip_for_tier tier =
  let base_ip = 50 in
  base_ip * tier * tier 