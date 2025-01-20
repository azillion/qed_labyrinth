open Base

type t = {
  id : string;
  send : Api.Protocol.server_message -> unit Lwt.t;
  mutable websocket : Dream.websocket option;
  mutable auth_state : auth_state;
}

and auth_state =
  | Anonymous
  | Authenticated of { user_id : string; character_id : string option }

let create client_id send_raw websocket =
  let send msg = 
    let json = Api.Protocol.server_message_to_yojson msg in
    send_raw (Yojson.Safe.to_string json)
  in
  { id = client_id; send; websocket; auth_state = Anonymous }

let set_ws t ws = t.websocket <- ws

let set_authenticated t user_id =
  t.auth_state <- Authenticated { user_id; character_id = None }

let set_character t character_id =
  match t.auth_state with
  | Authenticated auth ->
      t.auth_state <-
        Authenticated { auth with character_id = Some character_id }
  | Anonymous -> ()
