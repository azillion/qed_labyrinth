open Base

let handle_command body =
  let command = Command.parse body in
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
      Dream.json (handle_command body)
    );
  ]