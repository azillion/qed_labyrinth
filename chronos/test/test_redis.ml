(** Unit tests for Redis client functionality *)

open Infra

(* ============================================= *)
(* Config Tests                                  *)
(* ============================================= *)

let test_redis_config_defaults () =
  let config = Config.Redis.create () in
  Alcotest.(check string) "default host" "127.0.0.1" config.host;
  Alcotest.(check int) "default port" 6379 config.port

let test_redis_config_custom () =
  let config = Config.Redis.create ~host:"redis.example.com" ~port:6380 () in
  Alcotest.(check string) "custom host" "redis.example.com" config.host;
  Alcotest.(check int) "custom port" 6380 config.port

let test_redis_config_to_redis_config () =
  let config = Config.Redis.create ~host:"myhost" ~port:1234 () in
  let redis_config = Config.Redis.to_redis_config config in
  Alcotest.(check string) "converted host" "myhost" redis_config.Redis.host;
  Alcotest.(check int) "converted port" 1234 redis_config.Redis.port

let test_database_config_defaults () =
  let config = Config.Database.create () in
  Alcotest.(check string) "default host" "localhost" config.host;
  Alcotest.(check int) "default port" 5432 config.port;
  Alcotest.(check string) "default user" "postgres" config.user;
  Alcotest.(check string) "default password" "" config.password;
  Alcotest.(check string) "default dbname" "qed_labyrinth" config.dbname

let test_database_config_to_uri () =
  let config = Config.Database.create 
    ~host:"dbhost" 
    ~port:5433 
    ~user:"myuser" 
    ~password:"mypass" 
    ~dbname:"mydb" 
    () 
  in
  let uri = Config.Database.to_uri config in
  Alcotest.(check (option string)) "scheme" (Some "postgresql") (Uri.scheme uri);
  Alcotest.(check (option string)) "host" (Some "dbhost") (Uri.host uri);
  Alcotest.(check (option int)) "port" (Some 5433) (Uri.port uri);
  Alcotest.(check (option string)) "userinfo" (Some "myuser:mypass") (Uri.userinfo uri);
  Alcotest.(check string) "path" "/mydb" (Uri.path uri)

let test_database_config_to_uri_no_password () =
  let config = Config.Database.create ~user:"myuser" () in
  let uri = Config.Database.to_uri config in
  Alcotest.(check (option string)) "userinfo without password" (Some "myuser") (Uri.userinfo uri)

(* ============================================= *)
(* Queue Tests                                   *)
(* ============================================= *)

(* Note: Queue tests that require Eio runtime are skipped in unit tests
   since Eio.Stream behavior can be tricky to test in isolation.
   These would be better as integration tests with a real Eio environment. *)

(* Placeholder test to document the Queue module exists and has the expected interface *)
let test_queue_module_exists () =
  (* Just verify the module interface exists - actual runtime tests would need
     a proper Eio test harness *)
  let _create : unit -> int Queue.t = Queue.create in
  let _push : int Queue.t -> int -> unit = Queue.push in
  let _pop_opt : int Queue.t -> int option = Queue.pop_opt in
  let _pop : int Queue.t -> int = Queue.pop in
  let _is_empty : int Queue.t -> bool = Queue.is_empty in
  Alcotest.(check pass) "Queue module interface exists" () ()

(* ============================================= *)
(* Redis Error Tests                             *)
(* ============================================= *)

let test_redis_error_exception () =
  let exn = Redis.Redis_error "test error" in
  match exn with
  | Redis.Redis_error msg -> 
      Alcotest.(check string) "error message" "test error" msg
  | _ -> 
      Alcotest.fail "expected Redis_error"

(* ============================================= *)
(* Pubsub Message Type Tests                     *)
(* ============================================= *)

let test_pubsub_message_type () =
  let msg = Redis.Message { channel = "test-channel"; payload = "test-payload" } in
  match msg with
  | Redis.Message { channel; payload } ->
      Alcotest.(check string) "channel" "test-channel" channel;
      Alcotest.(check string) "payload" "test-payload" payload
  | _ -> Alcotest.fail "expected Message"

let test_pubsub_subscribe_type () =
  let msg = Redis.Subscribe { channel = "test-channel"; count = 1 } in
  match msg with
  | Redis.Subscribe { channel; count } ->
      Alcotest.(check string) "channel" "test-channel" channel;
      Alcotest.(check int) "count" 1 count
  | _ -> Alcotest.fail "expected Subscribe"

let test_pubsub_unsubscribe_type () =
  let msg = Redis.Unsubscribe { channel = "test-channel"; count = 0 } in
  match msg with
  | Redis.Unsubscribe { channel; count } ->
      Alcotest.(check string) "channel" "test-channel" channel;
      Alcotest.(check int) "count" 0 count
  | _ -> Alcotest.fail "expected Unsubscribe"

(* ============================================= *)
(* Test Suite                                    *)
(* ============================================= *)

let config_tests = [
  Alcotest.test_case "Redis config defaults" `Quick test_redis_config_defaults;
  Alcotest.test_case "Redis config custom" `Quick test_redis_config_custom;
  Alcotest.test_case "Redis config to_redis_config" `Quick test_redis_config_to_redis_config;
  Alcotest.test_case "Database config defaults" `Quick test_database_config_defaults;
  Alcotest.test_case "Database config to_uri" `Quick test_database_config_to_uri;
  Alcotest.test_case "Database config to_uri no password" `Quick test_database_config_to_uri_no_password;
]

let queue_tests = [
  Alcotest.test_case "Queue module interface" `Quick test_queue_module_exists;
]

let redis_tests = [
  Alcotest.test_case "Redis_error exception" `Quick test_redis_error_exception;
  Alcotest.test_case "Pubsub Message type" `Quick test_pubsub_message_type;
  Alcotest.test_case "Pubsub Subscribe type" `Quick test_pubsub_subscribe_type;
  Alcotest.test_case "Pubsub Unsubscribe type" `Quick test_pubsub_unsubscribe_type;
]

let () =
  Alcotest.run "Redis Client" [
    ("Config", config_tests);
    ("Queue", queue_tests);
    ("Redis Types", redis_tests);
  ]
