open Base
open Lwt.Syntax
open Yojson.Safe.Util

let generate_metadata ~context : (string * string, Qed_error.t) Result.t Lwt.t =
  (* Compose prompts *)
  let system_prompt =
    "You are a narrative designer crafting collectible Lore Cards for a fantasy RPG. Respond ONLY with valid JSON in the form {\"title\": \"<title>\", \"description\": \"<description>\"}." in
  let user_prompt =
    Printf.sprintf "Create a lore card for this event: %s" context
  in
  let* json_res = Infra.Ai_gateway.json_completion ~system:system_prompt ~user:user_prompt in
  match json_res with
  | Ok json ->
      let title = json |> member "title" |> to_string_option |> Option.value ~default:"Untitled Lore" in
      let description = json |> member "description" |> to_string_option |> Option.value ~default:"" in
      Lwt.return (Ok (title, description))
  | Error _ ->
      Lwt.return (Ok ("Untitled Lore", "")) 