open Base
open Lwt.Syntax
open State
(* Dummy value to mark the open State usage so compiler doesn't warn. *)
let _unused_state_type : t option = None

(* ------------------------------------------------------------------------- *)
(* Types                                                                     *)
(* ------------------------------------------------------------------------- *)

type schedule = PreUpdate | Update | PostUpdate

(** Conditions that determine when a system should execute. *)
type run_criteria =
  | OnEvent of string
  | OnTick

(** The signature every system handler must follow. *)
type handler = State.t -> string option -> Event.t option -> (unit, Qed_error.t) Result.t Lwt.t

(** Internal record storing a system together with its execution metadata. *)
 type system_record = {
  criteria : run_criteria;
  handler  : handler;
}

(* ------------------------------------------------------------------------- *)
(* Storage                                                                    *)
(* ------------------------------------------------------------------------- *)

let schedules : (schedule, system_record list) Hashtbl.t =
  Hashtbl.create (module struct
    type t = schedule

    let compare = Poly.compare
    let hash = Hashtbl.hash

    let sexp_of_t = function
      | PreUpdate -> Sexp.Atom "PreUpdate"
      | Update    -> Sexp.Atom "Update"
      | PostUpdate -> Sexp.Atom "PostUpdate"
  end)

let string_of_event_type (event : Event.t) =
  match event with
  | CreateCharacter _ -> "CreateCharacter"
  | CharacterCreated _ -> "CharacterCreated"
  | CharacterSelected _ -> "CharacterSelected"
  | Move _ -> "Move"
  | Say _ -> "Say"
  | CharacterListRequested _ -> "CharacterListRequested"
  | AreaQuery _ -> "AreaQuery"
  | AreaQueryResult _ -> "AreaQueryResult"
  | LoadAreaIntoECS _ -> "LoadAreaIntoECS"
  | PlayerMoved _ -> "PlayerMoved"
  | UpdateAreaPresence _ -> "UpdateAreaPresence"
  | AreaCreated _ -> "AreaCreated"
  | AreaCreationFailed _ -> "AreaCreationFailed"
  | ExitCreated _ -> "ExitCreated"
  | ExitCreationFailed _ -> "ExitCreationFailed"
  | SendMovementFailed _ -> "SendMovementFailed"
  | CharacterList _ -> "CharacterList"
  | LoadCharacterIntoECS _ -> "LoadCharacterIntoECS"
  | UnloadCharacterFromECS _ -> "UnloadCharacterFromECS"
  | SendChatHistory _ -> "SendChatHistory"
  | RequestChatHistory _ -> "RequestChatHistory"
  | Announce _ -> "Announce"
  | Tell _ -> "Tell"
  | Emote _ -> "Emote"
  | CharacterCreationFailed _ -> "CharacterCreationFailed"
  | CharacterSelectionFailed _ -> "CharacterSelectionFailed"
  | AreaQueryFailed _ -> "AreaQueryFailed"
  | TakeItem _ -> "TakeItem"
  | DropItem _ -> "DropItem"
  | RequestInventory _ -> "RequestInventory"
  | SendInventory _ -> "SendInventory"
  | TakeItemFailed _ -> "TakeItemFailed"
  | DropItemFailed _ -> "DropItemFailed"
  | ActionFailed _ -> "ActionFailed"
  | RequestAdminMetrics _ -> "RequestAdminMetrics"
  | _ -> "OtherEvent"

(* ------------------------------------------------------------------------- *)
(* Public API                                                                 *)
(* ------------------------------------------------------------------------- *)

let register ~schedule ~criteria handler =
  let record = { criteria; handler } in
  Hashtbl.update schedules schedule ~f:(function
    | None -> [ record ]
    | Some lst -> record :: lst )

(* ------------------------------------------------------------------------- *)
(* Execution helpers                                                          *)
(* ------------------------------------------------------------------------- *)

let run_tick_systems schedule state =
  let systems = Hashtbl.find schedules schedule |> Option.value ~default:[] in
  Lwt_list.iter_p
    (fun ({ criteria; handler } as _sys) ->
      match criteria with
      | OnTick ->
          let%lwt _ = handler state None None in
          Lwt.return_unit
      | OnEvent _ -> Lwt.return_unit )
    systems

let run_event_systems schedule state (trace_id, event) =
  let systems = Hashtbl.find schedules schedule |> Option.value ~default:[] in
  let event_key = string_of_event_type event in
  Lwt_list.iter_p
    (fun ({ criteria; handler } as _sys) ->
      match criteria with
      | OnEvent key when String.equal key event_key ->
          let%lwt _ = handler state (Some trace_id) (Some event) in
          Lwt.return_unit
      | _ -> Lwt.return_unit )
    systems

(* ------------------------------------------------------------------------- *)
(* Main entry point                                                           *)
(* ------------------------------------------------------------------------- *)

let run schedule st =
  (* 1. Drain the event queue so that we operate on a stable snapshot. *)
  let rec drain acc =
    match%lwt Infra.Queue.pop_opt st.event_queue with
    | None -> Lwt.return (List.rev acc)
    | Some (trace_id_opt, ev) ->
        let trace_id =
          Option.value trace_id_opt ~default:(
            let rng_state = Stdlib.Random.State.make_self_init () in
            Uuidm.to_string (Uuidm.v4_gen rng_state ())
          ) in
        drain ((trace_id, ev) :: acc)
  in
  let* events_for_tick = drain [] in

  (* 2. Run all tick-based systems for this schedule. *)
  let* () = run_tick_systems schedule st in

  (* 3. Feed every event to the matching systems. *)
  let* () = Lwt_list.iter_s (run_event_systems schedule st) events_for_tick in

  Lwt.return_unit 