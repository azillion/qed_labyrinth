type character = {
  id : string;
  name : string;
} [@@deriving yojson]

val character_of_model : Qed_domain.Character.t -> character