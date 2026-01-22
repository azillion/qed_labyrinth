(** RESP2 protocol implementation for Redis communication *)

type value =
  | Simple_string of string
  | Error of string
  | Integer of int
  | Bulk_string of string option
  | Array of value list option

let crlf = "\r\n"

(** Encode a single argument as a RESP bulk string *)
let encode_bulk_string s =
  Printf.sprintf "$%d%s%s%s" (String.length s) crlf s crlf

(** Encode a Redis command as a RESP array of bulk strings *)
let encode_command args =
  let buf = Buffer.create 64 in
  Buffer.add_string buf (Printf.sprintf "*%d%s" (List.length args) crlf);
  List.iter (fun arg -> Buffer.add_string buf (encode_bulk_string arg)) args;
  Buffer.contents buf

(** Read a line ending with \r\n from the buffer *)
let read_line reader =
  let line = Eio.Buf_read.line reader in
  (* Eio.Buf_read.line strips \n, but RESP has \r\n, so line should end with \r *)
  if String.length line > 0 && line.[String.length line - 1] = '\r' then
    String.sub line 0 (String.length line - 1)
  else
    line

(** Read exactly n bytes from the buffer *)
let read_bytes reader n =
  Eio.Buf_read.take n reader

(** Consume the trailing \r\n after bulk string data *)
let consume_crlf reader =
  let _ = Eio.Buf_read.take 2 reader in
  ()

(** Decode a RESP value from a buffered reader *)
let rec decode reader =
  let type_byte = Eio.Buf_read.any_char reader in
  match type_byte with
  | '+' ->
      (* Simple string *)
      let line = read_line reader in
      Simple_string line
  | '-' ->
      (* Error *)
      let line = read_line reader in
      Error line
  | ':' ->
      (* Integer *)
      let line = read_line reader in
      Integer (int_of_string line)
  | '$' ->
      (* Bulk string *)
      let line = read_line reader in
      let len = int_of_string line in
      if len < 0 then
        Bulk_string None
      else begin
        let data = read_bytes reader len in
        consume_crlf reader;
        Bulk_string (Some data)
      end
  | '*' ->
      (* Array *)
      let line = read_line reader in
      let count = int_of_string line in
      if count < 0 then
        Array None
      else begin
        let elements = List.init count (fun _ -> decode reader) in
        Array (Some elements)
      end
  | c ->
      failwith (Printf.sprintf "Unknown RESP type byte: %c" c)

let to_string_opt = function
  | Simple_string s -> Some s
  | Bulk_string (Some s) -> Some s
  | _ -> None

let to_int_opt = function
  | Integer i -> Some i
  | _ -> None

let to_array_opt = function
  | Array arr -> arr
  | _ -> None

let is_error = function
  | Error _ -> true
  | _ -> false

let error_message = function
  | Error msg -> Some msg
  | _ -> None
