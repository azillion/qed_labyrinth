open Base
open Error_utils

let process_event (state : State.t) (_trace_id : string option) (event : Event.t)
    : (unit, Qed_error.t) Result.t Lwt.t =
  match event with
  | Event.CharacterListRequested { user_id } ->
      Character_system.Character_list_system.handle_character_list_requested state user_id
  | Event.CreateCharacter { user_id; name; description; starting_area_id; might; finesse; wits; grit; presence } ->
      Character_system.Character_creation_system.handle_create_character state user_id name description starting_area_id might finesse wits grit presence
  | Event.CharacterSelected { user_id; character_id } ->
      Character_system.Character_selection_system.handle_character_selected state user_id character_id
  | Event.LoadCharacterIntoECS { user_id=_; character_id } ->
      Character_loading_system.handle_load_character state character_id
  | Event.UnloadCharacterFromECS { user_id; character_id } ->
      Character_unloading_system.handle_unload_character state user_id character_id
  | Event.AreaQuery { user_id; area_id } ->
      Area_management_system.Area_query_system.handle_area_query state user_id area_id
  | Event.AreaQueryResult { user_id; area } ->
      Area_management_system.Area_query_communication_system.handle_area_query_result state user_id area
  | Event.AreaQueryFailed { user_id; error } ->
      Area_management_system.Area_query_communication_system.handle_area_query_failed state user_id error
  | Event.CreateArea
    { user_id; name; description; x; y; z; elevation; temperature; moisture } ->
    wrap_ok (
      Area_management_system.Area_creation_system.handle_create_area
        state user_id name description x y z
        ?elevation ?temperature ?moisture ()
    )
  | Event.AreaCreated { user_id; area_id } ->
      Area_management_system.Area_creation_communication_system.handle_area_created state user_id area_id
  | Event.AreaCreationFailed { user_id; error } ->
      Area_management_system.Area_creation_communication_system.handle_area_creation_failed state user_id error
  | Event.CreateExit { user_id; from_area_id; to_area_id; direction; description=_; hidden=_; locked=_ } ->
      wrap_ok (
        Area_management_system.Exit_creation_system.handle_create_exit
          state user_id from_area_id to_area_id direction
      )
  | Event.ExitCreated { user_id; exit_id } ->
      Area_management_system.Exit_creation_communication_system.handle_exit_created
        state user_id exit_id
  | Event.ExitCreationFailed { user_id; error } ->
      Area_management_system.Exit_creation_communication_system.handle_exit_creation_failed state user_id error
  | Event.Move { user_id; direction } ->
      Movement_system.System.handle_move state user_id direction
  | Event.PlayerMoved { user_id; old_area_id; new_area_id; direction } ->
      Presence_system.System.handle_player_moved state user_id old_area_id new_area_id direction
  | Event.SendMovementFailed { user_id; reason } ->
      let open Lwt_result.Syntax in
      let* () = Publisher.publish_system_message_to_user state user_id reason in
      Lwt_result.return ()
  | Event.Say { user_id; content } ->
      Communication_system.System.handle_say state user_id content
  | Event.Announce { area_id; message } ->
      Communication_system.System.handle_announce
        state area_id message
  | Event.Tell { user_id; message } ->
      Communication_system.System.handle_tell state user_id message
  | Event.RequestChatHistory { user_id; area_id } ->
      Communication_system.Chat_history_system.handle_request_chat_history state user_id area_id
  | Event.SendChatHistory { user_id; messages } ->
      Communication_system.Chat_history_system.handle_send_chat_history state user_id messages
  | Event.UpdateAreaPresence { area_id=_; characters=_ } -> Lwt.return_ok ()
  | Event.SendInventory { user_id; items } ->
      let pb_items = List.map items ~f:(fun (item_id, name_, description_, quantity_) ->
        Schemas_generated.Output.{ id = item_id; name = name_; description = description_; quantity = Int32.of_int_exn quantity_ }) in
      let inventory_list_msg = Schemas_generated.Output.{ items = pb_items } in
      let output_event = Schemas_generated.Output.{ target_user_ids = [user_id]; payload = Inventory_list inventory_list_msg; trace_id = "" } in
      Publisher.publish_event state output_event
  | Event.ActionFailed { user_id; reason } ->
      Publisher.publish_system_message_to_user state user_id reason
  | _ -> Lwt.return_ok () 