val handle_login : Yojson.Safe.t -> Dream.response Lwt.t
val handle_register : Yojson.Safe.t -> Dream.response Lwt.t
val handle_logout : Dream.request -> Qed_domain.State.t -> Dream.response Lwt.t
