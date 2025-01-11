val handle_login : (module Caqti_lwt.CONNECTION) ->
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_register : (module Caqti_lwt.CONNECTION) ->
    Yojson.Safe.t ->
    Dream.response Lwt.t

val handle_verify : (module Caqti_lwt.CONNECTION) ->
    Dream.request ->
    Dream.response Lwt.t
