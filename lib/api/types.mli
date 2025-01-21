type character = {
  id : string;
  name : string;
} [@@deriving yojson]

val character_of_model : Qed_domain.Character.t -> character

type exit = {
  direction : string;
} [@@deriving yojson]

val exit_of_model : Qed_domain.Area.exit -> exit

type area = {
  name : string;
  description : string;
  exits : exit list;
} [@@deriving yojson]

val area_of_model : Qed_domain.Area.t -> Qed_domain.Area.exit list -> area

