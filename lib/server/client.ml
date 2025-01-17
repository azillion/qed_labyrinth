open Base

type t = {
  id : string;
  send : string -> unit Lwt.t;
  mutable websocket : Dream.websocket option;
  mutable auth_state : auth_state;
}

and auth_state =
  | Anonymous
  | Authenticated of { user_id : string; character_id : string option }

let create id send ws = { id; send; websocket = ws; auth_state = Anonymous }
let set_ws t ws = t.websocket <- ws

let set_authenticated t user_id =
  t.auth_state <- Authenticated { user_id; character_id = None }

let set_character t character_id =
  match t.auth_state with
  | Authenticated auth ->
      t.auth_state <-
        Authenticated { auth with character_id = Some character_id }
  | Anonymous -> ()
