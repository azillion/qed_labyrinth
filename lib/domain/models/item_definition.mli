open Base

type item_type = Weapon | Armor | Consumable | Misc
type slot = MainHand | OffHand | Head | Chest | Legs | Feet | None

type t = {
  id : string;
  name : string;
  description : string;
  item_type : item_type;
  slot : slot;
  weight : float;
  is_stackable : bool;
  properties : Yojson.Safe.t option;
}

val create :
  name:string ->
  description:string ->
  item_type:item_type ->
  ?slot:slot ->
  ?weight:float ->
  ?is_stackable:bool ->
  ?properties:Yojson.Safe.t ->
  unit ->
  (t, Qed_error.t) Result.t Lwt.t

val find_by_id : string -> (t option, Qed_error.t) Result.t Lwt.t 