open Base

(* This is the only new public type. The others are internal to the .ml file. *)
type t

val from_file : string -> (t, string) Result.t
val get_item_definitions : t -> Item_definition.t list
val get_areas : t -> (string * string * string * int * int * int * (string * int * string) list) list
val get_exits : t -> (string * string * string) list 
val get_lore_card_templates : t -> (string * string * int * int * string option * int option * string option * int option * string option * int option * string option) list 