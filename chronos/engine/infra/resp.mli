(** RESP2 protocol implementation for Redis communication *)

(** Redis RESP value types *)
type value =
  | Simple_string of string
  | Error of string
  | Integer of int
  | Bulk_string of string option  (** None represents nil bulk string *)
  | Array of value list option    (** None represents nil array *)

(** Encode a Redis command (list of arguments) into RESP wire format *)
val encode_command : string list -> string

(** Decode a RESP value from an Eio buffered reader *)
val decode : Eio.Buf_read.t -> value

(** Helper to extract string from a bulk string value *)
val to_string_opt : value -> string option

(** Helper to extract integer from an integer value *)
val to_int_opt : value -> int option

(** Helper to extract array from an array value *)
val to_array_opt : value -> value list option

(** Check if value is an error *)
val is_error : value -> bool

(** Get error message if value is an error *)
val error_message : value -> string option
