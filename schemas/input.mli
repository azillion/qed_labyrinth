
(** Code for input.proto *)

(* generated from "input.proto", do not edit *)



(** {2 Types} *)

type direction =
  | Unspecified 
  | North 
  | South 
  | East 
  | West 
  | Up 
  | Down 

type move_command = {
  direction : direction;
}

type say_command = {
  content : string;
}

type player_command =
  | Move of move_command
  | Say of say_command

type input_event = {
  user_id : string;
  trace_id : string;
  payload : player_command option;
}


(** {2 Basic values} *)

val default_direction : unit -> direction
(** [default_direction ()] is the default value for type [direction] *)

val default_move_command : 
  ?direction:direction ->
  unit ->
  move_command
(** [default_move_command ()] is the default value for type [move_command] *)

val default_say_command : 
  ?content:string ->
  unit ->
  say_command
(** [default_say_command ()] is the default value for type [say_command] *)

val default_player_command : unit -> player_command
(** [default_player_command ()] is the default value for type [player_command] *)

val default_input_event : 
  ?user_id:string ->
  ?trace_id:string ->
  ?payload:player_command option ->
  unit ->
  input_event
(** [default_input_event ()] is the default value for type [input_event] *)


(** {2 Formatters} *)

val pp_direction : Format.formatter -> direction -> unit 
(** [pp_direction v] formats v *)

val pp_move_command : Format.formatter -> move_command -> unit 
(** [pp_move_command v] formats v *)

val pp_say_command : Format.formatter -> say_command -> unit 
(** [pp_say_command v] formats v *)

val pp_player_command : Format.formatter -> player_command -> unit 
(** [pp_player_command v] formats v *)

val pp_input_event : Format.formatter -> input_event -> unit 
(** [pp_input_event v] formats v *)


(** {2 Protobuf Encoding} *)

val encode_pb_direction : direction -> Pbrt.Encoder.t -> unit
(** [encode_pb_direction v encoder] encodes [v] with the given [encoder] *)

val encode_pb_move_command : move_command -> Pbrt.Encoder.t -> unit
(** [encode_pb_move_command v encoder] encodes [v] with the given [encoder] *)

val encode_pb_say_command : say_command -> Pbrt.Encoder.t -> unit
(** [encode_pb_say_command v encoder] encodes [v] with the given [encoder] *)

val encode_pb_player_command : player_command -> Pbrt.Encoder.t -> unit
(** [encode_pb_player_command v encoder] encodes [v] with the given [encoder] *)

val encode_pb_input_event : input_event -> Pbrt.Encoder.t -> unit
(** [encode_pb_input_event v encoder] encodes [v] with the given [encoder] *)


(** {2 Protobuf Decoding} *)

val decode_pb_direction : Pbrt.Decoder.t -> direction
(** [decode_pb_direction decoder] decodes a [direction] binary value from [decoder] *)

val decode_pb_move_command : Pbrt.Decoder.t -> move_command
(** [decode_pb_move_command decoder] decodes a [move_command] binary value from [decoder] *)

val decode_pb_say_command : Pbrt.Decoder.t -> say_command
(** [decode_pb_say_command decoder] decodes a [say_command] binary value from [decoder] *)

val decode_pb_player_command : Pbrt.Decoder.t -> player_command
(** [decode_pb_player_command decoder] decodes a [player_command] binary value from [decoder] *)

val decode_pb_input_event : Pbrt.Decoder.t -> input_event
(** [decode_pb_input_event decoder] decodes a [input_event] binary value from [decoder] *)
