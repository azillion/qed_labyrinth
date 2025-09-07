open Base

type t = { entity_id: Uuidm.t; user_id: string }

let get_id ~character = Uuidm.to_string character.entity_id

let find_active ~state ~user_id =
  match State.get_active_character state user_id with
  | None -> Lwt_result.fail "You do not have an active character."
  | Some entity_id -> Lwt_result.return { entity_id; user_id }

let get_name ~character =
  let open Lwt_result.Syntax in
  let char_id_str = Uuidm.to_string character.entity_id in
  let* char_opt = Character.find_by_id char_id_str () in
  match char_opt with
  | Some c -> Lwt_result.return c.name
  | None -> Lwt_result.fail Qed_error.CharacterNotFound

let get_health ~character =
  let%lwt health_opt = Ecs.HealthStorage.get character.entity_id in
  Lwt.return (Option.map health_opt ~f:(fun h -> (h.current, h.max)))

let get_action_points ~character =
  let%lwt ap_opt = Ecs.ActionPointsStorage.get character.entity_id in
  Lwt.return (Option.map ap_opt ~f:(fun ap -> (ap.current, ap.max)))

let get_core_stats ~character =
  let%lwt core_opt = Ecs.CoreStatsStorage.get character.entity_id in
  Lwt.return (Option.map core_opt ~f:(fun c ->
    Types.{ might=c.might; finesse=c.finesse; wits=c.wits; grit=c.grit; presence=c.presence }))

let get_derived_stats ~character =
  let%lwt derived_opt = Ecs.DerivedStatsStorage.get character.entity_id in
  Lwt.return (Option.map derived_opt ~f:(fun d ->
    Types.{physical_power=d.physical_power; spell_power=d.spell_power; accuracy=d.accuracy; evasion=d.evasion; armor=d.armor; resolve=d.resolve}))

let get_progression ~character =
  let%lwt prog_opt = Ecs.ProgressionStorage.get character.entity_id in
  Lwt.return (Option.map prog_opt ~f:(fun p -> (p.proficiency_level, p.power_budget)))

