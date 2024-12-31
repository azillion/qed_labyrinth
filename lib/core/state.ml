type t = { current_space_id : Space.id; event_log : Event.t list }
[@@deriving yojson]

let initial_state = { current_space_id = ""; event_log = [] }

let create starting_space_id =
  { current_space_id = starting_space_id; event_log = [] }

let apply_event state = function
  | Event.PlayerMoved e ->
      { state with current_space_id = e.to_space_id }
  | Event.PlayerLooked _ -> state

let rebuild_from_events events = List.fold_left apply_event initial_state events
