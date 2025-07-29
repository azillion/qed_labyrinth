open Base
open Lwt.Syntax
open Infra
open State

(* ------------------------------------------------------------------------- *)
(* Types                                                                     *)
(* ------------------------------------------------------------------------- *)

type schedule = PreUpdate | Update | PostUpdate

(** Conditions that determine when a system should execute. *)
type run_criteria =
  | OnEvent of string
  | OnTick
  | OnComponentChange of string

(** The signature every system handler must follow. *)
type handler = State.t -> string option -> Event.t option -> (unit, Qed_error.t) Result.t Lwt.t

(** Internal record storing a system together with its execution metadata. *)
type system_record = {
  name : string;
  criteria : run_criteria;
  handler : handler;
  before : string list;
  after : string list;
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
      | Update -> Sexp.Atom "Update"
      | PostUpdate -> Sexp.Atom "PostUpdate"
  end)

(* ------------------------------------------------------------------------- *)
(* Registration API                                                           *)
(* ------------------------------------------------------------------------- *)

let register ~name ~schedule ~criteria ?(before = []) ?(after = []) handler =
  let record = { name; criteria; handler; before; after } in
  Hashtbl.update schedules schedule ~f:(function
    | None -> [ record ]
    | Some lst -> record :: lst )

(* ------------------------------------------------------------------------- *)
(* Dependency resolution                                                      *)
(* ------------------------------------------------------------------------- *)

(** Perform a topological sort of the systems respecting [before]/[after] dependencies. *)
let top_sort (systems : system_record list) : (system_record list, string) Result.t =
  (* Build adjacency list and in-degree table *)
  let graph = Hashtbl.create (module String) in
  let in_degree = Hashtbl.create (module String) in
  let system_map = Hashtbl.create (module String) in

  (* Helper to ensure keys exist *)
  let ensure_key tbl key default =
    if not (Hashtbl.mem tbl key) then Hashtbl.set tbl ~key ~data:default
  in

  List.iter systems ~f:(fun sys ->
      Hashtbl.set system_map ~key:sys.name ~data:sys;
      ensure_key graph sys.name [];
      ensure_key in_degree sys.name 0);

  (* Add edges based on dependencies *)
  List.iter systems ~f:(fun sys ->
      (* [after] means all in [after] -> sys *)
      List.iter sys.after ~f:(fun pred ->
          if Hashtbl.mem system_map pred then (
            Hashtbl.add_multi graph ~key:pred ~data:sys.name;
            Hashtbl.update in_degree sys.name ~f:(fun o -> Option.value o ~default:0 + 1)));
      (* [before] means sys -> each in [before] *)
      List.iter sys.before ~f:(fun succ ->
          if Hashtbl.mem system_map succ then (
            Hashtbl.add_multi graph ~key:sys.name ~data:succ;
            Hashtbl.update in_degree succ ~f:(fun o -> Option.value o ~default:0 + 1))));

  (* Kahn's algorithm *)
  let queue = Base.Queue.create () in
  Hashtbl.iteri in_degree ~f:(fun ~key ~data -> if data = 0 then Base.Queue.enqueue queue key);

  let sorted = ref [] in
  while not (Base.Queue.is_empty queue) do
    let v = Base.Queue.dequeue_exn queue in
    sorted := (Hashtbl.find_exn system_map v) :: !sorted;
    List.iter (Hashtbl.find_multi graph v) ~f:(fun succ ->
        Hashtbl.change in_degree succ ~f:(fun o ->
            o |> Option.map ~f:(fun d -> d - 1));
        match Hashtbl.find in_degree succ with
        | Some 0 -> Base.Queue.enqueue queue succ
        | _ -> ())
  done;

  (* A cycle is detected if not all unique systems were sorted. Using the number of unique
       system names avoids false positives when the same system is registered multiple times
       with different criteria (e.g. OnTick vs OnEvent). *)
  let unique_system_count = Hashtbl.length system_map in
  if List.length !sorted <> unique_system_count then (
    (* Collect the names of systems that could not be scheduled to aid debugging *)
    let unscheduled =
      List.filter systems ~f:(fun s -> not (List.exists !sorted ~f:(fun r -> String.equal r.name s.name)))
      |> List.map ~f:(fun s -> s.name)
    in
    let data = [ ("unscheduled_systems", String.concat ~sep:", " unscheduled) ] in
    Lwt.ignore_result (Monitoring.Log.error "Cycle detected in system dependencies" ~data ());
    Error "Cycle detected")
  else Ok (List.rev !sorted)

(* ------------------------------------------------------------------------- *)
(* Utility                                                                    *)
(* ------------------------------------------------------------------------- *)

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
  | CreateArea _ -> "CreateArea"
  | CreateExit _ -> "CreateExit"
  | Equip _ -> "Equip"
  | Unequip _ -> "Unequip"
  | RequestCharacterSheet _ -> "RequestCharacterSheet"
  (* Progression & Lore Card *)
  | AwardExperience _ -> "AwardExperience"
  | PlayerGainedExperience _ -> "PlayerGainedExperience"
  | PlayerLeveledUp _ -> "PlayerLeveledUp"
  | AwardLoreCard _ -> "AwardLoreCard"
  | LoreCardAwarded _ -> "LoreCardAwarded"
  | CharacterActivated _ -> "CharacterActivated"
  | ActivateLoreCard _ -> "ActivateLoreCard"
  | DeactivateLoreCard _ -> "DeactivateLoreCard"
  | LoadoutChanged _ -> "LoadoutChanged"
  | RequestLoreCollection _ -> "RequestLoreCollection"
  | PlayerDisconnected _ -> "PlayerDisconnected"

(* ------------------------------------------------------------------------- *)
(* Helper to filter runnable systems                                          *)
(* ------------------------------------------------------------------------- *)

let get_runnable_systems schedule _state events_for_tick =
  let all_systems = Hashtbl.find schedules schedule |> Option.value ~default:[] in
  let event_keys =
    let module StringSet = Set.M(String) in
    List.map events_for_tick ~f:(fun (_, e) -> string_of_event_type e)
    |> Set.of_list (module String)
  in
  let changed_components = Ecs.World.StorageRegistry.get_all_modified_components () in
  List.filter all_systems ~f:(fun sys ->
      match sys.criteria with
      | OnTick -> true
      | OnEvent key -> Set.mem event_keys key
      | OnComponentChange name -> Set.mem changed_components name)

(* ------------------------------------------------------------------------- *)
(* Main entry point                                                           *)
(* ------------------------------------------------------------------------- *)

let run ?events schedule state =
  (* Use provided events snapshot or drain the queue ourselves *)
  let drain_if_needed () =
    match events with
    | Some evs -> Lwt.return evs
    | None ->
        let rec drain_queue acc =
          match%lwt Infra.Queue.pop_opt state.event_queue with
          | None -> Lwt.return (List.rev acc)
          | Some (trace_id_opt, event) ->
              drain_queue ((trace_id_opt, event) :: acc)
        in
        drain_queue []
  in
  let* events_for_tick = drain_if_needed () in
  let runnable_systems = get_runnable_systems schedule state events_for_tick in
  match top_sort runnable_systems with
  | Error _ -> Lwt.return_unit (* Error already logged in [top_sort] *)
  | Ok sorted_systems ->
      (* Execute systems in dependency order *)
      Lwt_list.iter_s
        (fun system ->
          match system.criteria with
          | OnTick | OnComponentChange _ ->
              let%lwt _ = system.handler state None None in
              Lwt.return_ok () |> Lwt.map (fun _ -> ())
          | OnEvent key ->
              let relevant_events =
                List.filter events_for_tick ~f:(fun (_, e) -> String.equal (string_of_event_type e) key)
              in
              Lwt_list.iter_s
                (fun (trace_id_opt, event) ->
                  let%lwt _ = system.handler state trace_id_opt (Some event) in
                  Lwt.return_unit)
                relevant_events)
        sorted_systems 