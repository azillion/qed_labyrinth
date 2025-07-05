(lang dune 3.0)
(name qed_labyrinth)
(generate_opam_files true)

(package
 (name qed_labyrinth)
 (version 0.1.0)
 (synopsis "Agent-driven social simulation MUD")
 (description "A text-based world where aliveness emerges from autonomous agents interacting in intimate social spaces")
 (source
 (github "azillion/qed_labyrinth"))
 (documentation "https://github.com/azillion/qed_labyrinth")
 (license MIT)
 (authors "azillionbytes <azillionbytes@gmail.com>")
 (maintainers "azillionbytes <azillionbytes@gmail.com>")
 (homepage "https://github.com/azillion/qed_labryinth")
 (bug_reports "https://github.com/azillion/qed_labryinth")

 (depends
  (ocaml (>= 5.0.0))
  (dune (>= 3.0.0))
  (base (>= v0.16.0))
  (ppx_jane (>= v0.16.0))  ; Useful for deriving, inline_test, etc
  (ppx_let (>= v0.16.0))   ; For monadic syntax
  (alcotest :with-test)     ; For unit testing - good to have from start
  
  ; Core dependencies for MVP
  (yojson (>= 2.1.0))                ; JSON handling
  (ppx_deriving_yojson (>= 3.7.0))   ; JSON deriving
  (ppx_deriving (>= 5.2.1))          ; General deriving
  (digestif (>= 0.8.0))              ; Hashing
  (pbrt (>= 3.0))                    ; Protocol buffer runtime

  ;; Future dependencies - uncomment as needed
  ; Network & Database - for post-MVP
  (dream (>= 1.0.0~alpha4))          ; Async web framework
  (caqti (>= 1.9.0))                 ; Database abstraction
  (caqti-driver-postgresql (>= 1.9.0)); Postgres driver
  (caqti-lwt (>= 1.9.0))             ; Async DB interface
  (caqti-driver-sqlite3 (>= 1.9.0))
  (caqti-driver-postgresql (>= 1.9.0))
  ; (ppx_yojson_conv (>= 0.1.0))       ; Additional JSON support
  ; (qcheck :with-test)                ; Property testing for later
  ; (ppx_rapper (>= 3.1.0))             ; For SQL queries
  ; (ppx_rapper_lwt (>= 3.1.0))         ; For SQL queries
  ))
