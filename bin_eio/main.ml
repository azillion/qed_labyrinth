open Base

let () =
  Eio_main.run @@ fun env ->
  let stdout = Eio.Stdenv.stdout env in
  Eio.Flow.copy_string "Chronos Engine (Eio) starting...\n" stdout;
  
  (* TODO: Database connection with caqti-eio *)
  (* TODO: Redis connection (need Eio-compatible client) *)
  (* TODO: Main event loop *)
  
  Eio.Flow.copy_string "Engine initialized.\n" stdout
