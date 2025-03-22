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