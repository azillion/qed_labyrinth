open Base
open Ppx_yojson_conv_lib.Yojson_conv.Primitives


type command_object = {
  command : string;
} [@@deriving yojson]

let handle_command body =
  let command = Command.parse body in
  ignore (Printf.sprintf "Command: %s\n" (Command.show_command command));
  match command with 
  | Look -> "You look around..."
  | Say msg -> Printf.sprintf "You say: %s" msg
  | Unknown -> "Unknown command"

let () =
  Dream.run ~port:3000
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "<h1>Hello, OCaml!</h1>");

    Dream.post "/command" (fun request ->
      let%lwt body = Dream.body request in
      let cmd_obj =
        body
        |> Yojson.Safe.from_string
        |> command_object_of_yojson
      in
      Dream.json (handle_command cmd_obj.command)
    );
  ]