type create_character_payload = {
      user_id: string;
      name: string;
      description: string;
      starting_area_id: string;
      might: int;
      finesse: int;
      wits: int;
      grit: int;
      presence: int;
    }
type character_created_payload = { user_id: string; character_id: string }
type character_creation_failed_payload = { user_id: string; error: string }
type character_selected_payload = { user_id: string; character_id: string }
type character_activated_payload = { user_id: string; character_id: string }
type character_selection_failed_payload = { user_id: string; error: string }
type load_character_into_ecs_payload = { user_id: string; character_id: string }
type unload_character_from_ecs_payload = { user_id: string; character_id: string }
type character_list_requested_payload = { user_id: string }
type character_list_payload = { user_id: string; characters: (string * string) list }
type create_area_payload = {
    user_id: string;
    name: string;
    description: string;
    x: int;
    y: int;
    z: int;
    elevation: float option;
    temperature: float option;
    moisture: float option;
  }
type area_created_payload = { user_id: string; area_id: string }
type area_creation_failed_payload = { user_id: string; error: Yojson.Safe.t }
type create_exit_payload = {
    user_id: string;
    from_area_id: string;
    to_area_id: string;
    direction: Components.ExitComponent.direction;
    description: string option;
    hidden: bool;
    locked: bool;
  }
type exit_created_payload = { user_id: string; exit_id: string }
type exit_creation_failed_payload = { user_id: string; error: Yojson.Safe.t }
type area_query_payload = { user_id: string; area_id: string }
type area_query_result_payload = { user_id: string; area: Types.area }
type area_query_failed_payload = { user_id: string; error: Yojson.Safe.t }
type load_area_into_ecs_payload = { area_id: string }
type move_payload = { user_id: string; direction: Components.ExitComponent.direction }
type player_moved_payload = { user_id: string; old_area_id: string; new_area_id: string; direction: Components.ExitComponent.direction }
type send_movement_failed_payload = { user_id: string; reason: string }
type say_payload = { user_id: string; content: string }
type emote_payload = { user_id: string; content: string }
type announce_payload = { area_id: string; message: Communication.t }
type tell_payload = { user_id: string; message: Communication.t }
type request_chat_history_payload = { user_id: string; area_id: string }
type send_chat_history_payload = { user_id: string; messages: Types.chat_message list }
type update_area_presence_payload = { area_id: string; characters: Types.list_character list }
type take_item_payload = { user_id: string; character_id: string; item_entity_id: string }
type drop_item_payload = { user_id: string; character_id: string; item_entity_id: string }
type request_inventory_payload = { user_id: string; character_id: string }
type send_inventory_payload = { user_id: string; items: (string * string * string * int) list }
type take_item_failed_payload = { user_id: string; reason: string }
type drop_item_failed_payload = { user_id: string; reason: string }
type action_failed_payload = { user_id: string; reason: string }
type request_admin_metrics_payload = { user_id: string }
type equip_payload = { user_id: string; character_id: string; item_entity_id: string }
type unequip_payload = { user_id: string; character_id: string; slot: Item_definition.slot }
type request_character_sheet_payload = { user_id: string; character_id: string }

(* Progression & Lore Card Events *)
type award_experience_payload = { character_id: string; xp: int; ip: int }
type player_gained_experience_payload = { character_id: string }
type player_leveled_up_payload = { user_id: string; new_level: int; new_power_budget: int }
type award_lore_card_payload = { character_id: string; template_id: string; context: string option }
type lore_card_awarded_payload = { user_id: string; card: Lore_card.Instance.t }
type activate_lore_card_payload = { user_id: string; character_id: string; card_instance_id: string }
type deactivate_lore_card_payload = { user_id: string; character_id: string; card_instance_id: string }
type loadout_changed_payload = { character_id: string }
type request_lore_collection_payload = { user_id: string; character_id: string }
type spawn_npc_payload = { archetype_id: string; location_id: string }

(* Disconnection Events *)
type player_disconnected_payload = { user_id: string }

type t =
  | CreateCharacter of create_character_payload
  | CharacterCreated of character_created_payload
  | CharacterCreationFailed of character_creation_failed_payload
  | CharacterSelected of character_selected_payload
  | CharacterActivated of character_activated_payload
  | CharacterSelectionFailed of character_selection_failed_payload
  | LoadCharacterIntoECS of load_character_into_ecs_payload
  | UnloadCharacterFromECS of unload_character_from_ecs_payload
  | CharacterListRequested of character_list_requested_payload
  | CharacterList of character_list_payload
  
  (* Area management events *)
  | CreateArea of create_area_payload
  | AreaCreated of area_created_payload
  | AreaCreationFailed of area_creation_failed_payload
  | CreateExit of create_exit_payload
  | ExitCreated of exit_created_payload
  | ExitCreationFailed of exit_creation_failed_payload
  | AreaQuery of area_query_payload
  | AreaQueryResult of area_query_result_payload
  | AreaQueryFailed of area_query_failed_payload
  | LoadAreaIntoECS of load_area_into_ecs_payload

  (* Movement events *)
  | Move of move_payload
  | PlayerMoved of player_moved_payload
  | SendMovementFailed of send_movement_failed_payload

  (* Communication Events *)
  | Say of say_payload
  | Emote of emote_payload
  | Announce of announce_payload
  | Tell of tell_payload
  | RequestChatHistory of request_chat_history_payload
  | SendChatHistory of send_chat_history_payload

  (* Presence Events *)
  | UpdateAreaPresence of update_area_presence_payload
  
  (* Item & Inventory Events *)
  | TakeItem of take_item_payload
  | DropItem of drop_item_payload
  | RequestInventory of request_inventory_payload
  | SendInventory of send_inventory_payload
  | TakeItemFailed of take_item_failed_payload
  | DropItemFailed of drop_item_failed_payload
  | ActionFailed of action_failed_payload

  (* Admin Events *)
  | RequestAdminMetrics of request_admin_metrics_payload

  (* Equipment Events *)
  | Equip of equip_payload
  | Unequip of unequip_payload

  (* Character Sheet Events *)
  | RequestCharacterSheet of request_character_sheet_payload

  (* Progression & Lore Card Events *)
  | AwardExperience of award_experience_payload
  | PlayerGainedExperience of player_gained_experience_payload
  | PlayerLeveledUp of player_leveled_up_payload
  | AwardLoreCard of award_lore_card_payload
  | LoreCardAwarded of lore_card_awarded_payload
  | ActivateLoreCard of activate_lore_card_payload
  | DeactivateLoreCard of deactivate_lore_card_payload
  | LoadoutChanged of loadout_changed_payload
  | RequestLoreCollection of request_lore_collection_payload
  | SpawnNpc of spawn_npc_payload
  (* Connection Management Events *)
  | PlayerDisconnected of player_disconnected_payload

(* Helper to extract user_id for error reporting *)
let get_user_id = function
  | CreateCharacter e -> Some e.user_id
  | CharacterCreated e -> Some e.user_id
  | CharacterCreationFailed e -> Some e.user_id
  | CharacterSelected e -> Some e.user_id
  | CharacterActivated e -> Some e.user_id
  | CharacterSelectionFailed e -> Some e.user_id
  | LoadCharacterIntoECS e -> Some e.user_id
  | UnloadCharacterFromECS e -> Some e.user_id
  | CharacterListRequested e -> Some e.user_id
  | CharacterList e -> Some e.user_id
  | CreateArea e -> Some e.user_id
  | AreaCreated e -> Some e.user_id
  | AreaCreationFailed e -> Some e.user_id
  | CreateExit e -> Some e.user_id
  | ExitCreated e -> Some e.user_id
  | ExitCreationFailed e -> Some e.user_id
  | AreaQuery e -> Some e.user_id
  | AreaQueryResult e -> Some e.user_id
  | AreaQueryFailed e -> Some e.user_id
  | Move e -> Some e.user_id
  | PlayerMoved e -> Some e.user_id
  | SendMovementFailed e -> Some e.user_id
  | Say e -> Some e.user_id
  | Emote e -> Some e.user_id
  | Tell e -> Some e.user_id
  | RequestChatHistory e -> Some e.user_id
  | SendChatHistory e -> Some e.user_id
  | TakeItem e -> Some e.user_id
  | DropItem e -> Some e.user_id
  | RequestInventory e -> Some e.user_id
  | SendInventory e -> Some e.user_id
  | TakeItemFailed e -> Some e.user_id
  | DropItemFailed e -> Some e.user_id
  | ActionFailed e -> Some e.user_id
  | RequestAdminMetrics e -> Some e.user_id
  | Equip e -> Some e.user_id
  | Unequip e -> Some e.user_id
  | RequestCharacterSheet e -> Some e.user_id
  | PlayerLeveledUp e -> Some e.user_id
  | LoreCardAwarded e -> Some e.user_id
  | ActivateLoreCard e -> Some e.user_id
  | DeactivateLoreCard e -> Some e.user_id
  | LoadoutChanged _ -> None
  | RequestLoreCollection e -> Some e.user_id
  | SpawnNpc _ -> None
  | PlayerDisconnected e -> Some e.user_id
  | _ -> None