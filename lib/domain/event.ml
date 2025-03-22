type t =
  | CreateCharacter of {
      user_id: string;
      name: string;
      description: string;
      starting_area_id: string;
    }
  | CharacterCreated of { user_id: string; character_id: string }
  | CharacterCreationFailed of { user_id: string; error: string }
  | SelectCharacter of { user_id: string; character_id: string }
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

  (* Area events *)
  | AreaInfo of { user_id: string; character_id: string; area_id: string }
  | AreaInfoFailed of { user_id: string; character_id: string; error: Yojson.Safe.t }