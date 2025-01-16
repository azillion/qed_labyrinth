val handle_login : 
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_register : 
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_verify : 
    Dream.request ->
    Dream.response Lwt.t

val handle_logout : 
    Dream.request ->
    State.t ->
    Dream.response Lwt.t
