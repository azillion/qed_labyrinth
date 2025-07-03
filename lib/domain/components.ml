module CharacterComponent = struct
  type t = {
    entity_id: string;
    user_id: string;  (* Links character to the owning user *)
  } [@@deriving yojson]

  let table_name = "characters"
end

module CharacterPositionComponent = struct
  type t = {
    entity_id: string;
    area_id: string;  (* entity ID of the area where the character is located *)
  } [@@deriving yojson]

  let table_name = "character_positions"
end

module DescriptionComponent = struct
  type t = {
    entity_id: string;
    name: string;
    description: string option;
  } [@@deriving yojson]

  let table_name = "descriptions"
end

module AreaComponent = struct
  type t = {
    entity_id: string;
    x: int;
    y: int;
    z: int;
    elevation: float option;
    temperature: float option;
    moisture: float option;
  } [@@deriving yojson]

  let table_name = "areas"
end

module ExitComponent = struct
  type direction = 
    | North 
    | South 
    | East 
    | West 
    | Up 
    | Down [@@deriving yojson]
    
  type t = {
    entity_id: string;
    from_area_id: string;
    to_area_id: string;
    direction: direction;
    description: string option;
    hidden: bool;
    locked: bool;
  } [@@deriving yojson]

  let table_name = "exits"
  
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

module AuthenticationComponent = struct
  type t = {
    entity_id: string;
    username: string;
    password_hash: string;
    token: string option;
    token_expires_at: float option; (* Unix timestamp *)
  } [@@deriving yojson]

  let table_name = "authentications"
end

module UserProfileComponent = struct
  type role = Player | Admin | SuperAdmin [@@deriving yojson]

  let string_of_role = function
    | Player -> "player"
    | Admin -> "admin"
    | SuperAdmin -> "super admin"

  type t = {
    entity_id: string;
    email: string;
    role: role;
    created_at: float; (* Unix timestamp *)
  } [@@deriving yojson]

  let table_name = "user_profiles"
end

module CommunicationComponent = struct
  type t = {
    entity_id: string;
    area_id: string option;
    sender_id: string option;
    message_type: Types.message_type;
    content: string;
    timestamp: float;
  } [@@deriving yojson]

  let table_name = "communications"
end
