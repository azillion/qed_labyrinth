open Base
open Lwt.Syntax
open Infra

(* Type alias repeated here for clarity *)
type handler = State.t -> string option -> Event.t -> (unit, Qed_error.t) Result.t Lwt.t

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
  | SendChatHistory _        -> "SendChatHistory"
  | RequestChatHistory _     -> "RequestChatHistory"
  | Announce _               -> "Announce"
  | Tell _                   -> "Tell"
  | Emote _                  -> "Emote"
  | CharacterCreationFailed _-> "CharacterCreationFailed"
  | CharacterSelectionFailed _-> "CharacterSelectionFailed"
  | AreaQueryFailed _        -> "AreaQueryFailed"
  | TakeItem _ -> "TakeItem"
  | DropItem _ -> "DropItem"
  | RequestInventory _ -> "RequestInventory"
  | SendInventory _ -> "SendInventory"
  | TakeItemFailed _ -> "TakeItemFailed"
  | DropItemFailed _ -> "DropItemFailed"
  | ActionFailed _ -> "ActionFailed"
  | RequestAdminMetrics _ -> "RequestAdminMetrics"
  | _ -> "OtherEvent"

let handlers : (string, handler) Hashtbl.t = Hashtbl.create (module String)

let register key handler =
  Hashtbl.set handlers ~key ~data:handler

let has_handler key =
  Hashtbl.mem handlers key

let dispatch state trace_id event =
  let key = string_of_event_type event in
  match Hashtbl.find handlers key with
  | Some handler -> handler state trace_id event
  | None ->
      let* () = Monitoring.Log.warn "No handler registered for event" ~data:[("type", key)] () in
      Lwt.return_ok ()

let register_legacy_systems () = Lwt.return_unit 