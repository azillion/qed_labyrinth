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

val encode_output_event : output_event -> Pbrt.Encoder.t 