val error_response : status:Dream.status -> string -> Dream.response Lwt.t

val user_response : token:string -> Model.User.t -> Dream.response Lwt.t

val handle_login : (module Caqti_lwt.CONNECTION) ->
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_register : (module Caqti_lwt.CONNECTION) ->
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_verify : (module Caqti_lwt.CONNECTION) ->
    Dream.request ->
    Dream.response Lwt.t
