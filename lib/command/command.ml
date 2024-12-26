[@@@warning "-32"]  (* Suppress unused value warnings for generated show functions *)

open Base

type command =
  | Look
  | Say of string
  | Unknown
[@@deriving show]

let parse (input : string) : command =
  let tokens = String.split ~on:' ' input |> List.filter ~f:(Fn.non String.is_empty) in
  match tokens with
  | [] -> Unknown
  | cmd :: rest ->
    match cmd with
    | "look" -> Look
    | "say" -> Say (String.concat ~sep:" " rest)
    | _ -> Unknown