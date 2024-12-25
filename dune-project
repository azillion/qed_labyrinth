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
  (alcotest :with-test)     ; For unit testing
  (qcheck :with-test)))     ; For property-based testing
