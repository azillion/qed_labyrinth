(lang dune 3.0)
(name qed_labyrinth)
(generate_opam_files true)
(package
 (name qed_labyrinth)
 (version 0.1.0)
 (synopsis "Agent-driven social simulation MUD")
 (description "A text-based world where aliveness emerges from autonomous agents interacting in intimate social spaces")
 (depends
  (ocaml (>= 5.0.0))
  (dune (>= 3.0.0))
  (base (>= v0.16.0))
  (ppx_jane (>= v0.16.0))  ; Useful for deriving, inline_test, etc
  (ppx_let (>= v0.16.0))   ; For monadic syntax
  ; (alcotest :with-test)     ; For unit testing
  ; (qcheck :with-test)       ; For property-based testing
  
  ; Network & Database
  (dream (>= 1.0.0~alpha4))          ; Async web framework
  (caqti (>= 1.9.0))                 ; Database abstraction
  ; (caqti-driver-postgresql (>= 1.9.0)); Postgres driver
  (caqti-lwt (>= 1.9.0))             ; Async DB interface
  (yojson (>= 2.1.0))                ; JSON handling
  (ppx_deriving_yojson (>= 3.7.0))
  (ppx_yojson_conv (>= 0.1.0))
  (ppx_deriving (>= 5.2.1))))