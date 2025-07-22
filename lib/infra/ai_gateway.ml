open Lwt.Syntax

(* Simple text completion *)
let simple_completion ~system ~user : (string, string) Result.t Lwt.t =
  let%lwt res = Llm_client.generate_with_openai ~system_prompt:system ~user_prompt:user in
  match res with
  | Ok txt -> Lwt.return (Ok txt)
  | Error e ->
      let%lwt () = Monitoring.Log.error "LLM simple_completion failed" ~data:[("error", e)] () in
      Lwt.return (Error e)

(* JSON completion. Ensures returned text parses to valid JSON. *)
let json_completion ~system ~user : (Yojson.Safe.t, string) Result.t Lwt.t =
  let* txt_res = simple_completion ~system ~user in
  match txt_res with
  | Error e -> Lwt.return (Error e)
  | Ok txt -> (
      try
        let json = Yojson.Safe.from_string txt in
        Lwt.return (Ok json)
      with exn ->
        let msg = Printf.sprintf "Invalid JSON from LLM: %s" (Printexc.to_string exn) in
        let%lwt () = Monitoring.Log.error "LLM returned invalid JSON" ~data:[("error", msg); ("response", txt)] () in
        Lwt.return (Error msg)) 