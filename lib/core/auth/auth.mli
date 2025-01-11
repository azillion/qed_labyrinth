type error = [
    | `UserNotFound
    | `InvalidPassword
    | `UsernameTaken
    | `TokenExpired
    | `InvalidToken
    | `DatabaseError of string
]

module Make(Db : Caqti_lwt.CONNECTION) : sig
  val authenticate_user : username:string -> password:string -> (string, [> error]) result Lwt.t
  val verify_token : string -> (string, [> error]) result
end