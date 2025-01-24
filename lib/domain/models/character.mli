type t = {
  id : string;
  user_id : string;
  name : string;
  location_id : string;
  created_at : Ptime.t;
  deleted_at : Ptime.t option;
}

type error =
  | CharacterNotFound
  | UserNotFound
  | NameTaken
  | DatabaseError of string
[@@deriving yojson]

val create :
  user_id:string ->
  name:string ->
  (t, error) result Lwt.t

val find_by_id :
  string ->
  (t, error) result Lwt.t

val find_by_user_and_name :
  user_id:string ->
  name:string ->
  (t, error) result Lwt.t

val find_all_by_user :
  user_id:string ->
  (t list, error) result Lwt.t

val soft_delete :
  character_id:string ->
  (unit, error) result Lwt.t

val move :
  character_id:string ->
  direction:Area.direction ->
  (string, error) result Lwt.t
