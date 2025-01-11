type t = {
  id : string;
  username : string;
  email : string;
  created_at : Ptime.t;
}

type error =
  | UserNotFound
  | InvalidPassword
  | UsernameTaken
  | EmailTaken
  | DatabaseError of string

val register :
  db:(module Caqti_lwt.CONNECTION) ->
  username:string ->
  password:string ->
  email:string ->
  (t, error) result Lwt.t

val authenticate :
  db:(module Caqti_lwt.CONNECTION) ->
  username:string ->
  password:string ->
  (t, error) result Lwt.t

val find_by_id :
  db:(module Caqti_lwt.CONNECTION) ->
  string ->
  (t option, error) result Lwt.t

val find_by_username :
  db:(module Caqti_lwt.CONNECTION) ->
  string ->
  (t option, error) result Lwt.t