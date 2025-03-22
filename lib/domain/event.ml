type t =
  | CreateCharacter of {
      user_id: string;
      name: string;
      description: string;
      starting_area_id: string;
    }
  | CharacterCreated of { user_id: string; character_id: string }
  | CharacterCreationFailed of { user_id: string; error: string }
  | CharacterSelected of { user_id: string; character_id: string }
  | CharacterSelectionFailed of { user_id: string; error: string }
  | CharacterListRequested of { user_id: string }
  | CharacterList of { user_id: string; characters: (string * string) list }
  
  (* Communication events *)
  | SendCharacterList of { user_id: string; characters: Types.list_character list }
  | SendCharacterCreated of { user_id: string; character: Types.list_character }
  | SendCharacterCreationFailed of { user_id: string; error: Yojson.Safe.t }
  | SendCharacterSelected of { user_id: string; character: Types.character }
  | SendCharacterSelectionFailed of { user_id: string; error: Yojson.Safe.t }

  (* Area management events *)
  | CreateArea of { 
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
  | AreaCreated of { user_id: string; area_id: string }
  | AreaCreationFailed of { user_id: string; error: Yojson.Safe.t }
  | CreateExit of {
      user_id: string;
      from_area_id: string;
      to_area_id: string;
      direction: Components.ExitComponent.direction;
      description: string option;
      hidden: bool;
      locked: bool;
    }
  | ExitCreated of { user_id: string; exit_id: string }
  | ExitCreationFailed of { user_id: string; error: Yojson.Safe.t }
  | AreaQuery of { user_id: string; area_id: string }
  | AreaQueryResult of { user_id: string; area: Types.area }
  | AreaQueryFailed of { user_id: string; error: Yojson.Safe.t }