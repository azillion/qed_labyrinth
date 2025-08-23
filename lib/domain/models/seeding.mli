open Base

(* This is the only new public type. The others are internal to the .ml file. *)
type t

val from_file : string -> (t, string) Result.t
val get_item_definitions : t -> Item_definition.t list
val get_areas : t -> (string * string * string * int * int * int * (string * int * string) list) list
val get_exits : t -> (string * string * string) list 
val get_lore_card_templates :
  t ->
  ( string * string * int * int
  * string option (* default_title *)
  * string option (* default_description *)
  * string option * int option  (* bonus_1 *)
  * string option * int option  (* bonus_2 *)
  * string option * int option  (* bonus_3 *)
  * string option              (* grants_ability *) )
  list 

module Internal : sig
  type archetype_props = {
    id: string;
    version: int;
    params: Yojson.Safe.t;
    prompts: Yojson.Safe.t;
  }
end

val get_archetypes : t -> Internal.archetype_props list