module CharacterComponent = struct
  type t = {
    entity_id: string;
    user_id: string;  (* Links character to the owning user *)
  } [@@deriving yojson]

  let table_name = "character_entities"
end

module CharacterPositionComponent = struct
  type t = {
    entity_id: string;
    area_id: string;  (* entity ID of the area where the character is located *)
  } [@@deriving yojson]

  let table_name = "character_positions"
end

module DescriptionComponent = struct
  (* Deprecated – description data now lives in Tier-1 relational tables. *)
  type t = unit [@@deriving yojson]
  let table_name = "descriptions_removed"
end

module AreaComponent = struct
  (* Deprecated – area data now lives in Tier-1 relational tables. *)
  type t = unit [@@deriving yojson]
  let table_name = "area_components_removed"
end

module ExitComponent = struct
  (* Only the types and helper functions needed by other modules *)
  type direction = 
    | North 
    | South 
    | East 
    | West 
    | Up 
    | Down [@@deriving yojson]
    
  let direction_to_string = function
    | North -> "north"
    | South -> "south"
    | East -> "east"
    | West -> "west"
    | Up -> "up"
    | Down -> "down"
    
  let string_to_direction = function
    | "north" -> Some North
    | "south" -> Some South
    | "east" -> Some East
    | "west" -> Some West
    | "up" -> Some Up
    | "down" -> Some Down
    | _ -> None
    
  let opposite_direction = function
    | North -> South
    | South -> North
    | East -> West
    | West -> East
    | Up -> Down
    | Down -> Up
end


module CoreStatsComponent = struct
  type t = {
    entity_id: string;
    might: int;
    finesse: int;
    wits: int;
    grit: int;
    presence: int;
  } [@@deriving yojson]

  let table_name = "core_stats"
end

module DerivedStatsComponent = struct
  type t = {
    entity_id: string;
    physical_power: int;
    spell_power: int;
    accuracy: int;
    evasion: int;
    armor: int;
    resolve: int;
  } [@@deriving yojson]

  let table_name = "derived_stats"
end

module HealthComponent = struct
  type t = {
    entity_id: string;
    current: int;
    max: int;
  } [@@deriving yojson]

  let table_name = "healths"
end

module ActionPointsComponent = struct
  type t = {
    entity_id: string;
    current: int;
    max: int;
  } [@@deriving yojson]

  let table_name = "action_points"
end

module ItemComponent = struct
  type t = {
    entity_id: string;
    item_definition_id: string;
    quantity: int;
  } [@@deriving yojson]

  let table_name = "items"
end

module InventoryComponent = struct
  type t = {
    entity_id: string;
    items: string list; (* List of item entity IDs *)
  } [@@deriving yojson]

  let table_name = "inventories"
end

module ItemPositionComponent = struct
  type t = {
    entity_id: string;
    area_id: string; (* Item is located in this area *)
  } [@@deriving yojson]

  let table_name = "item_positions"
end

module ArchetypeComponent = struct
  type t = {
    entity_id: string;
    archetype_id: string;
  } [@@deriving yojson]
  let table_name = "archetype_ids"
end

module PhysicalityComponent = struct
  type t = {
    entity_id: string;
    can_speak: bool;
    can_manipulate_objects: bool;
  } [@@deriving yojson]
  let table_name = "physicalities"
end

module BehaviorComponent = struct
  type t = {
    entity_id: string;
    traits: string list;
  } [@@deriving yojson]
  let table_name = "behaviors"
end

module GoalComponent = struct
  type t = {
    entity_id: string;
    active_goal: string; (* e.g., "Idle", "MoveTo" *)
    context: Yojson.Safe.t; (* e.g., {"destination_id": "loc_123"} *)
  } [@@deriving yojson]
  let table_name = "goals"
end

module ProgressionComponent = struct
  type t = {
    entity_id: string;
    proficiency_level: int;
    current_xp: int;
    saga_tier: int;
    current_ip: int;
    power_budget: int;
  } [@@deriving yojson]

  let table_name = "progression"
end

module ActiveBonusesComponent = struct
  type t = {
    entity_id: string;
    might: int;
    finesse: int;
    wits: int;
    grit: int;
    presence: int;
  } [@@deriving yojson]

  let table_name = "active_bonuses"

  let empty entity_id = { entity_id; might=0; finesse=0; wits=0; grit=0; presence=0 }
end

module AbilitiesComponent = struct
  type t = {
    entity_id: string;
    unlocked_abilities: string list;
  } [@@deriving yojson]

  let table_name = "abilities"
end