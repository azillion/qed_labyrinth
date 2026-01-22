open Base

let () =
  Eio_main.run @@ fun env ->
  let stdout = Eio.Stdenv.stdout env in
  let net = Eio.Stdenv.net env in
  
  Eio.Flow.copy_string "Chronos Engine (Eio) starting...\n" stdout;
  
  (* Load configuration from environment *)
  let config = Infra.Config.load () in
  let redis_config = Infra.Config.Redis.to_redis_config config.redis in
  
  Eio.Flow.copy_string 
    (Printf.sprintf "Connecting to Redis at %s:%d...\n" 
      redis_config.host redis_config.port) 
    stdout;
  
  (* Create a switch for managing connection lifetime *)
  Eio.Switch.run @@ fun sw ->
  
  (* Connect to Redis *)
  let redis_conn = Infra.Redis.connect ~sw ~net redis_config in
  Eio.Flow.copy_string "Redis connected.\n" stdout;
  
  (* Create application state *)
  let _state : unit Domain.State.t = Domain.State.create redis_conn in
  Eio.Flow.copy_string "Application state initialized.\n" stdout;
  
  (* TODO: Database connection with caqti-eio *)
  (* TODO: Register systems *)
  (* TODO: Main event loop with subscriber fiber *)
  
  (* Example: Test Redis connection with a simple ping-pong via SET/GET *)
  Infra.Redis.set redis_conn "chronos:status" "running";
  (match Infra.Redis.get redis_conn "chronos:status" with
  | Some status -> 
      Eio.Flow.copy_string (Printf.sprintf "Redis test: status = %s\n" status) stdout
  | None -> 
      Eio.Flow.copy_string "Redis test: no status found\n" stdout);
  
  Eio.Flow.copy_string "Engine initialized successfully.\n" stdout;
  
  (* Clean up *)
  let _ = Infra.Redis.del redis_conn ["chronos:status"] in
  ()
