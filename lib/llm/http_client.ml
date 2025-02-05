open Cohttp_lwt_unix
open Lwt.Infix

type http_error =
  | ConnectionError of string
  | TimeoutError
  | ResponseError of int * string

exception RequestTimeout

let post_request ?(timeout=200.0) ~headers ~body uri =
  let body_str = match body with
  | None -> ""
  | Some b -> b
  in
  
  let%lwt response = Lwt.pick [
    Client.post ~headers ~body:(`String body_str) uri;
    (Lwt_unix.sleep timeout >>= fun () -> Lwt.fail RequestTimeout)
  ] in
  
  match response with
  | (resp, body) ->
      let%lwt body_str = Cohttp_lwt.Body.to_string body in
      let status = Cohttp.Response.status resp |> Cohttp.Code.code_of_status in
      if status >= 200 && status < 300 then
        Lwt.return_ok body_str
      else
        Lwt.return_error (ResponseError (status, body_str))
  | exception RequestTimeout ->
      Lwt.return_error TimeoutError
  | exception Unix.Unix_error(err, _, _) ->
      Lwt.return_error (ConnectionError (Unix.error_message err))