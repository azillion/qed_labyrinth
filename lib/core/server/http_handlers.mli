val error_response : status:Dream.status -> string -> Dream.response Lwt.t

val user_response : token:string -> Model.User.t -> Dream.response Lwt.t

val handle_login : 
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_register : 
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_verify : 
    Dream.request ->
    Dream.response Lwt.t
