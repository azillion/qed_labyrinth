type t = {
  knockout_time: float; (* Unix timestamp *)
} [@@deriving yojson]

let table_name = "unconscious_states"
