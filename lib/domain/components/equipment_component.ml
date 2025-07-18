open Base

type t = {
  entity_id: string;
  main_hand: string option;
  off_hand: string option;
  head: string option;
  chest: string option;
  legs: string option;
  feet: string option;
} [@@deriving yojson, fields]

let table_name = "equipments"

let empty entity_id = {
  entity_id;
  main_hand = None;
  off_hand = None;
  head = None;
  chest = None;
  legs = None;
  feet = None;
} 