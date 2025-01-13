(* type character = { id : string; name : string; location_id : string }
   [@@deriving yojson] *)

type auth_message =
  | Register of { username : string; password : string; email : string }
  | Login of { username : string; password : string }
  | Verify of { token : string }
  | Logout

type client_message =
  | CreateCharacter of { name : string }
    (* | SelectCharacter of { character_id : string } *)
[@@deriving yojson]

type server_message =
  (* | CharacterList of { characters : character list }
     | CharacterCreated of { character : character }
     | CharacterSelected of { character : character } *)
  | Error of { message : string }
[@@deriving yojson]
