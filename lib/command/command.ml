open Base

type command =
  | Look
  | Say of string
  | Unknown
[@@deriving yojson]

let parse (input : string) : command =
  let tokens = String.split ~on:' ' input |> List.filter ~f:(Fn.non String.is_empty) in
  match tokens with
  | [] -> Unknown
  | cmd :: rest ->
    match cmd with
    | "look" -> Look
    | "say" -> Say (String.concat ~sep:" " rest)
    | _ -> Unknown