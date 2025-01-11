open Base

type error = [
  | `UserNotFound
  | `InvalidPassword 
  | `UsernameTaken
  | `TokenExpired
  | `InvalidToken
  | `DatabaseError of string
]

module Make(Db : Caqti_lwt.CONNECTION) = struct
  module Model = Model.Make(Db)

  let error_of_user_error = function
    | Model.User.UserNotFound -> `UserNotFound
    | Model.User.InvalidPassword -> `InvalidPassword
    | Model.User.UsernameTaken -> `UsernameTaken
    | Model.User.EmailTaken -> `UsernameTaken
    | Model.User.DatabaseError msg -> `DatabaseError msg

  let authenticate_user ~username ~password =
    let open Lwt_result.Infix in
    Model.User.authenticate ~username ~password 
    |> Lwt_result.map_error error_of_user_error
    >>= fun user ->
    match Jwt.generate_token user.id with
    | Ok token -> Lwt.return_ok token
    | Error _ -> Lwt.return_error `InvalidToken

  let verify_token token = 
    match Jwt.verify_token token with
    | Ok user_id -> Ok user_id 
    | Error `Expired -> Error `TokenExpired
    | Error _ -> Error `InvalidToken
end