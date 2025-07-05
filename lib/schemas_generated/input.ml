[@@@ocaml.warning "-27-30-39-44"]

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

let rec default_direction () = (Unspecified:direction)

let rec default_move_command 
  ?direction:((direction:direction) = default_direction ())
  () : move_command  = {
  direction;
}

let rec default_say_command 
  ?content:((content:string) = "")
  () : say_command  = {
  content;
}

let rec default_player_command () : player_command = Move (default_move_command ())

let rec default_input_event 
  ?user_id:((user_id:string) = "")
  ?trace_id:((trace_id:string) = "")
  ?payload:((payload:player_command option) = None)
  () : input_event  = {
  user_id;
  trace_id;
  payload;
}

type move_command_mutable = {
  mutable direction : direction;
}

let default_move_command_mutable () : move_command_mutable = {
  direction = default_direction ();
}

type say_command_mutable = {
  mutable content : string;
}

let default_say_command_mutable () : say_command_mutable = {
  content = "";
}

type input_event_mutable = {
  mutable user_id : string;
  mutable trace_id : string;
  mutable payload : player_command option;
}

let default_input_event_mutable () : input_event_mutable = {
  user_id = "";
  trace_id = "";
  payload = None;
}

[@@@ocaml.warning "-27-30-39"]

(** {2 Formatters} *)

let rec pp_direction fmt (v:direction) =
  match v with
  | Unspecified -> Format.fprintf fmt "Unspecified"
  | North -> Format.fprintf fmt "North"
  | South -> Format.fprintf fmt "South"
  | East -> Format.fprintf fmt "East"
  | West -> Format.fprintf fmt "West"
  | Up -> Format.fprintf fmt "Up"
  | Down -> Format.fprintf fmt "Down"

let rec pp_move_command fmt (v:move_command) = 
  let pp_i fmt () =
    Pbrt.Pp.pp_record_field ~first:true "direction" pp_direction fmt v.direction;
  in
  Pbrt.Pp.pp_brk pp_i fmt ()

let rec pp_say_command fmt (v:say_command) = 
  let pp_i fmt () =
    Pbrt.Pp.pp_record_field ~first:true "content" Pbrt.Pp.pp_string fmt v.content;
  in
  Pbrt.Pp.pp_brk pp_i fmt ()

let rec pp_player_command fmt (v:player_command) =
  match v with
  | Move x -> Format.fprintf fmt "@[<hv2>Move(@,%a)@]" pp_move_command x
  | Say x -> Format.fprintf fmt "@[<hv2>Say(@,%a)@]" pp_say_command x

let rec pp_input_event fmt (v:input_event) = 
  let pp_i fmt () =
    Pbrt.Pp.pp_record_field ~first:true "user_id" Pbrt.Pp.pp_string fmt v.user_id;
    Pbrt.Pp.pp_record_field ~first:false "trace_id" Pbrt.Pp.pp_string fmt v.trace_id;
    Pbrt.Pp.pp_record_field ~first:false "payload" (Pbrt.Pp.pp_option pp_player_command) fmt v.payload;
  in
  Pbrt.Pp.pp_brk pp_i fmt ()

[@@@ocaml.warning "-27-30-39"]

(** {2 Protobuf Encoding} *)

let rec encode_pb_direction (v:direction) encoder =
  match v with
  | Unspecified -> Pbrt.Encoder.int_as_varint (0) encoder
  | North -> Pbrt.Encoder.int_as_varint 1 encoder
  | South -> Pbrt.Encoder.int_as_varint 2 encoder
  | East -> Pbrt.Encoder.int_as_varint 3 encoder
  | West -> Pbrt.Encoder.int_as_varint 4 encoder
  | Up -> Pbrt.Encoder.int_as_varint 5 encoder
  | Down -> Pbrt.Encoder.int_as_varint 6 encoder

let rec encode_pb_move_command (v:move_command) encoder = 
  encode_pb_direction v.direction encoder;
  Pbrt.Encoder.key 1 Pbrt.Varint encoder; 
  ()

let rec encode_pb_say_command (v:say_command) encoder = 
  Pbrt.Encoder.string v.content encoder;
  Pbrt.Encoder.key 1 Pbrt.Bytes encoder; 
  ()

let rec encode_pb_player_command (v:player_command) encoder = 
  begin match v with
  | Move x ->
    Pbrt.Encoder.nested encode_pb_move_command x encoder;
    Pbrt.Encoder.key 1 Pbrt.Bytes encoder; 
  | Say x ->
    Pbrt.Encoder.nested encode_pb_say_command x encoder;
    Pbrt.Encoder.key 2 Pbrt.Bytes encoder; 
  end

let rec encode_pb_input_event (v:input_event) encoder = 
  Pbrt.Encoder.string v.user_id encoder;
  Pbrt.Encoder.key 1 Pbrt.Bytes encoder; 
  Pbrt.Encoder.string v.trace_id encoder;
  Pbrt.Encoder.key 2 Pbrt.Bytes encoder; 
  begin match v.payload with
  | Some x -> 
    Pbrt.Encoder.nested encode_pb_player_command x encoder;
    Pbrt.Encoder.key 3 Pbrt.Bytes encoder; 
  | None -> ();
  end;
  ()

[@@@ocaml.warning "-27-30-39"]

(** {2 Protobuf Decoding} *)

let rec decode_pb_direction d = 
  match Pbrt.Decoder.int_as_varint d with
  | 0 -> (Unspecified:direction)
  | 1 -> (North:direction)
  | 2 -> (South:direction)
  | 3 -> (East:direction)
  | 4 -> (West:direction)
  | 5 -> (Up:direction)
  | 6 -> (Down:direction)
  | _ -> Pbrt.Decoder.malformed_variant "direction"

let rec decode_pb_move_command d =
  let v = default_move_command_mutable () in
  let continue__= ref true in
  while !continue__ do
    match Pbrt.Decoder.key d with
    | None -> (
    ); continue__ := false
    | Some (1, Pbrt.Varint) -> begin
      v.direction <- decode_pb_direction d;
    end
    | Some (1, pk) -> 
      Pbrt.Decoder.unexpected_payload "Message(move_command), field(1)" pk
    | Some (_, payload_kind) -> Pbrt.Decoder.skip d payload_kind
  done;
  ({
    direction = v.direction;
  } : move_command)

let rec decode_pb_say_command d =
  let v = default_say_command_mutable () in
  let continue__= ref true in
  while !continue__ do
    match Pbrt.Decoder.key d with
    | None -> (
    ); continue__ := false
    | Some (1, Pbrt.Bytes) -> begin
      v.content <- Pbrt.Decoder.string d;
    end
    | Some (1, pk) -> 
      Pbrt.Decoder.unexpected_payload "Message(say_command), field(1)" pk
    | Some (_, payload_kind) -> Pbrt.Decoder.skip d payload_kind
  done;
  ({
    content = v.content;
  } : say_command)

let rec decode_pb_player_command d = 
  let rec loop () = 
    let ret:player_command = match Pbrt.Decoder.key d with
      | None -> Pbrt.Decoder.malformed_variant "player_command"
      | Some (1, _) -> (Move (decode_pb_move_command (Pbrt.Decoder.nested d)) : player_command) 
      | Some (2, _) -> (Say (decode_pb_say_command (Pbrt.Decoder.nested d)) : player_command) 
      | Some (n, payload_kind) -> (
        Pbrt.Decoder.skip d payload_kind; 
        loop () 
      )
    in
    ret
  in
  loop ()

let rec decode_pb_input_event d =
  let v = default_input_event_mutable () in
  let continue__= ref true in
  while !continue__ do
    match Pbrt.Decoder.key d with
    | None -> (
    ); continue__ := false
    | Some (1, Pbrt.Bytes) -> begin
      v.user_id <- Pbrt.Decoder.string d;
    end
    | Some (1, pk) -> 
      Pbrt.Decoder.unexpected_payload "Message(input_event), field(1)" pk
    | Some (2, Pbrt.Bytes) -> begin
      v.trace_id <- Pbrt.Decoder.string d;
    end
    | Some (2, pk) -> 
      Pbrt.Decoder.unexpected_payload "Message(input_event), field(2)" pk
    | Some (3, Pbrt.Bytes) -> begin
      v.payload <- Some (decode_pb_player_command (Pbrt.Decoder.nested d));
    end
    | Some (3, pk) -> 
      Pbrt.Decoder.unexpected_payload "Message(input_event), field(3)" pk
    | Some (_, payload_kind) -> Pbrt.Decoder.skip d payload_kind
  done;
  ({
    user_id = v.user_id;
    trace_id = v.trace_id;
    payload = v.payload;
  } : input_event)
