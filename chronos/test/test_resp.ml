(** Unit tests for the RESP protocol implementation *)

open Infra

(* Helper to create a buffered reader from a string *)
let reader_of_string s =
  let flow = Eio.Flow.string_source s in
  Eio.Buf_read.of_flow ~max_size:1_000_000 flow

(* ============================================= *)
(* Encoding Tests                                *)
(* ============================================= *)

let test_encode_simple_command () =
  let cmd = Resp.encode_command ["PING"] in
  Alcotest.(check string) "PING command" "*1\r\n$4\r\nPING\r\n" cmd

let test_encode_get_command () =
  let cmd = Resp.encode_command ["GET"; "mykey"] in
  Alcotest.(check string) "GET command" "*2\r\n$3\r\nGET\r\n$5\r\nmykey\r\n" cmd

let test_encode_set_command () =
  let cmd = Resp.encode_command ["SET"; "key"; "value"] in
  Alcotest.(check string) "SET command" "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n" cmd

let test_encode_empty_value () =
  let cmd = Resp.encode_command ["SET"; "key"; ""] in
  Alcotest.(check string) "SET with empty value" "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$0\r\n\r\n" cmd

let test_encode_hset_command () =
  let cmd = Resp.encode_command ["HSET"; "myhash"; "field1"; "value1"] in
  Alcotest.(check string) "HSET command" 
    "*4\r\n$4\r\nHSET\r\n$6\r\nmyhash\r\n$6\r\nfield1\r\n$6\r\nvalue1\r\n" cmd

(* ============================================= *)
(* Decoding Tests                                *)
(* ============================================= *)

let resp_value_testable =
  let pp fmt v = 
    match v with
    | Resp.Simple_string s -> Format.fprintf fmt "Simple_string(%s)" s
    | Resp.Error s -> Format.fprintf fmt "Error(%s)" s
    | Resp.Integer i -> Format.fprintf fmt "Integer(%d)" i
    | Resp.Bulk_string None -> Format.fprintf fmt "Bulk_string(nil)"
    | Resp.Bulk_string (Some s) -> Format.fprintf fmt "Bulk_string(%s)" s
    | Resp.Array None -> Format.fprintf fmt "Array(nil)"
    | Resp.Array (Some _) -> Format.fprintf fmt "Array(...)"
  in
  let eq a b =
    match a, b with
    | Resp.Simple_string a, Resp.Simple_string b -> String.equal a b
    | Resp.Error a, Resp.Error b -> String.equal a b
    | Resp.Integer a, Resp.Integer b -> Int.equal a b
    | Resp.Bulk_string None, Resp.Bulk_string None -> true
    | Resp.Bulk_string (Some a), Resp.Bulk_string (Some b) -> String.equal a b
    | Resp.Array None, Resp.Array None -> true
    | Resp.Array (Some a), Resp.Array (Some b) -> List.length a = List.length b
    | _ -> false
  in
  Alcotest.testable pp eq

let run_decode s =
  Eio_main.run @@ fun _ ->
  let reader = reader_of_string s in
  Resp.decode reader

let test_decode_simple_string () =
  let result = run_decode "+OK\r\n" in
  Alcotest.(check resp_value_testable) "simple string" (Resp.Simple_string "OK") result

let test_decode_simple_string_pong () =
  let result = run_decode "+PONG\r\n" in
  Alcotest.(check resp_value_testable) "PONG response" (Resp.Simple_string "PONG") result

let test_decode_error () =
  let result = run_decode "-ERR unknown command\r\n" in
  Alcotest.(check resp_value_testable) "error" (Resp.Error "ERR unknown command") result

let test_decode_integer () =
  let result = run_decode ":1000\r\n" in
  Alcotest.(check resp_value_testable) "integer" (Resp.Integer 1000) result

let test_decode_integer_zero () =
  let result = run_decode ":0\r\n" in
  Alcotest.(check resp_value_testable) "integer zero" (Resp.Integer 0) result

let test_decode_integer_negative () =
  let result = run_decode ":-1\r\n" in
  Alcotest.(check resp_value_testable) "negative integer" (Resp.Integer (-1)) result

let test_decode_bulk_string () =
  let result = run_decode "$6\r\nfoobar\r\n" in
  Alcotest.(check resp_value_testable) "bulk string" (Resp.Bulk_string (Some "foobar")) result

let test_decode_bulk_string_empty () =
  let result = run_decode "$0\r\n\r\n" in
  Alcotest.(check resp_value_testable) "empty bulk string" (Resp.Bulk_string (Some "")) result

let test_decode_bulk_string_nil () =
  let result = run_decode "$-1\r\n" in
  Alcotest.(check resp_value_testable) "nil bulk string" (Resp.Bulk_string None) result

let test_decode_array () =
  let result = run_decode "*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n" in
  match result with
  | Resp.Array (Some [Resp.Bulk_string (Some "foo"); Resp.Bulk_string (Some "bar")]) ->
      Alcotest.(check pass) "array with two elements" () ()
  | _ -> Alcotest.fail "expected array with foo and bar"

let test_decode_array_empty () =
  let result = run_decode "*0\r\n" in
  match result with
  | Resp.Array (Some []) -> Alcotest.(check pass) "empty array" () ()
  | _ -> Alcotest.fail "expected empty array"

let test_decode_array_nil () =
  let result = run_decode "*-1\r\n" in
  Alcotest.(check resp_value_testable) "nil array" (Resp.Array None) result

let test_decode_nested_array () =
  (* Array containing: [1, [2, 3], "hello"] *)
  let result = run_decode "*3\r\n:1\r\n*2\r\n:2\r\n:3\r\n$5\r\nhello\r\n" in
  match result with
  | Resp.Array (Some [Resp.Integer 1; Resp.Array (Some [Resp.Integer 2; Resp.Integer 3]); Resp.Bulk_string (Some "hello")]) ->
      Alcotest.(check pass) "nested array" () ()
  | _ -> Alcotest.fail "expected nested array"

(* ============================================= *)
(* Helper Function Tests                         *)
(* ============================================= *)

let test_to_string_opt_simple () =
  let result = Resp.to_string_opt (Resp.Simple_string "hello") in
  Alcotest.(check (option string)) "simple string to string" (Some "hello") result

let test_to_string_opt_bulk () =
  let result = Resp.to_string_opt (Resp.Bulk_string (Some "world")) in
  Alcotest.(check (option string)) "bulk string to string" (Some "world") result

let test_to_string_opt_nil () =
  let result = Resp.to_string_opt (Resp.Bulk_string None) in
  Alcotest.(check (option string)) "nil bulk string to string" None result

let test_to_string_opt_integer () =
  let result = Resp.to_string_opt (Resp.Integer 42) in
  Alcotest.(check (option string)) "integer to string" None result

let test_to_int_opt_integer () =
  let result = Resp.to_int_opt (Resp.Integer 42) in
  Alcotest.(check (option int)) "integer to int" (Some 42) result

let test_to_int_opt_string () =
  let result = Resp.to_int_opt (Resp.Simple_string "hello") in
  Alcotest.(check (option int)) "string to int" None result

let test_is_error_true () =
  let result = Resp.is_error (Resp.Error "something went wrong") in
  Alcotest.(check bool) "is error" true result

let test_is_error_false () =
  let result = Resp.is_error (Resp.Simple_string "OK") in
  Alcotest.(check bool) "is not error" false result

let test_error_message_some () =
  let result = Resp.error_message (Resp.Error "ERR not found") in
  Alcotest.(check (option string)) "error message" (Some "ERR not found") result

let test_error_message_none () =
  let result = Resp.error_message (Resp.Simple_string "OK") in
  Alcotest.(check (option string)) "no error message" None result

(* ============================================= *)
(* Test Suite                                    *)
(* ============================================= *)

let encoding_tests = [
  Alcotest.test_case "encode PING command" `Quick test_encode_simple_command;
  Alcotest.test_case "encode GET command" `Quick test_encode_get_command;
  Alcotest.test_case "encode SET command" `Quick test_encode_set_command;
  Alcotest.test_case "encode SET with empty value" `Quick test_encode_empty_value;
  Alcotest.test_case "encode HSET command" `Quick test_encode_hset_command;
]

let decoding_tests = [
  Alcotest.test_case "decode simple string OK" `Quick test_decode_simple_string;
  Alcotest.test_case "decode simple string PONG" `Quick test_decode_simple_string_pong;
  Alcotest.test_case "decode error" `Quick test_decode_error;
  Alcotest.test_case "decode integer" `Quick test_decode_integer;
  Alcotest.test_case "decode integer zero" `Quick test_decode_integer_zero;
  Alcotest.test_case "decode negative integer" `Quick test_decode_integer_negative;
  Alcotest.test_case "decode bulk string" `Quick test_decode_bulk_string;
  Alcotest.test_case "decode empty bulk string" `Quick test_decode_bulk_string_empty;
  Alcotest.test_case "decode nil bulk string" `Quick test_decode_bulk_string_nil;
  Alcotest.test_case "decode array" `Quick test_decode_array;
  Alcotest.test_case "decode empty array" `Quick test_decode_array_empty;
  Alcotest.test_case "decode nil array" `Quick test_decode_array_nil;
  Alcotest.test_case "decode nested array" `Quick test_decode_nested_array;
]

let helper_tests = [
  Alcotest.test_case "to_string_opt simple string" `Quick test_to_string_opt_simple;
  Alcotest.test_case "to_string_opt bulk string" `Quick test_to_string_opt_bulk;
  Alcotest.test_case "to_string_opt nil" `Quick test_to_string_opt_nil;
  Alcotest.test_case "to_string_opt integer" `Quick test_to_string_opt_integer;
  Alcotest.test_case "to_int_opt integer" `Quick test_to_int_opt_integer;
  Alcotest.test_case "to_int_opt string" `Quick test_to_int_opt_string;
  Alcotest.test_case "is_error true" `Quick test_is_error_true;
  Alcotest.test_case "is_error false" `Quick test_is_error_false;
  Alcotest.test_case "error_message some" `Quick test_error_message_some;
  Alcotest.test_case "error_message none" `Quick test_error_message_none;
]

let () =
  Alcotest.run "RESP Protocol" [
    ("Encoding", encoding_tests);
    ("Decoding", decoding_tests);
    ("Helpers", helper_tests);
  ]
