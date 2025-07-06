(* Types mirrored from .mli *)

type chat_message = {
  sender_name : string;
  content : string;
  message_type : string;
}

type exit = { direction : string }

type area_update = {
  area_id : string;
  name : string;
  description : string;
  exits : exit list;
}

type payload =
  | Chat_message of chat_message
  | Area_update of area_update

type output_event = {
  target_user_ids : string list;
  payload : payload option;
}

let encode_output_event (_ : output_event) : Pbrt.Encoder.t =
  (* Stub implementation: returns an empty encoder *)
  Pbrt.Encoder.create () 