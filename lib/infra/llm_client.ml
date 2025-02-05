open Llm
open Types

module ClaudeClient = Client.Make(Anthropic.Anthropic)(Provider_limits.ClaudeLimits)
module OpenAIClient = Client.Make(Openai.Openai)(Provider_limits.OpenAILimits)
module DeepseekClient = Client.Make(Deepseek.Deepseek)(Provider_limits.DeepseekLimits)

let claude_client_ref : ClaudeClient.t option ref = ref None
let openai_client_ref : OpenAIClient.t option ref = ref None
let deepseek_client_ref : DeepseekClient.t option ref = ref None

let create_openai_client () =
  let config = Openai.Openai.create_config
    ~api_key:(Sys.getenv "OPENAI_API_KEY")
    ~model:"o1-mini"
    ~use_options:false
    () in
  OpenAIClient.create config

let get_openai_client () =
  match !openai_client_ref with
  | Some client -> 
      client
  | None ->
      let client = create_openai_client () in
      openai_client_ref := Some client;
      client

let create_deepseek_client () =
  let config = Deepseek.Deepseek.create_config
    ~api_key:(Sys.getenv "DEEPSEEK_API_KEY")
    ~model:"deepseek-chat"
    ~base_url:"https://api.deepseek.com/v1"
    () in
  DeepseekClient.create config

let get_deepseek_client () =
  match !deepseek_client_ref with
  | Some client -> 
      client
  | None ->
      let client = create_deepseek_client () in
      deepseek_client_ref := Some client;
      client

let create_claude_client () =
  let config = Anthropic.Anthropic.create_config
    ~api_key:(Sys.getenv "ANTHROPIC_API_KEY")
    () in
  ClaudeClient.create config

let get_claude_client () =
  match !claude_client_ref with
  | Some client -> 
      client
  | None ->
      let client = create_claude_client () in
      claude_client_ref := Some client;
      client

let generate_with_openai ~system_prompt ~user_prompt =
  let client = get_openai_client () in
  let messages = [
    { role = User;
      content = system_prompt;
      name = None;
      tool_calls = None };
    { role = User;
      content = user_prompt;
      name = None;
      tool_calls = None };
  ] in
  let%lwt result = OpenAIClient.complete client ~messages () in
  match result with
  | Ok response -> 
      Lwt.return (Ok response.text)
  | Error e -> 
      Lwt.return (Error (string_of_error e))

let generate_with_deepseek ~system_prompt ~user_prompt =
  let client = get_deepseek_client () in
  let messages = [
    { role = System;
      content = system_prompt;
      name = None;
      tool_calls = None };
    { role = User;
      content = user_prompt;
      name = None;
      tool_calls = None };
  ] in
  (* Stdio.print_endline (Printf.sprintf "Sending messages to Deepseek: %s" (String.concat "\n" (List.map (fun m -> m.content) messages))); *)
  let%lwt result = DeepseekClient.complete client ~messages () in
  match result with
  | Ok response -> 
      Lwt.return (Ok response.text)
  | Error e -> 
      Lwt.return (Error (string_of_error e))

let generate_with_claude ~system_prompt ~user_prompt =
  let client = get_claude_client () in
  let messages = [
    { role = System;
      content = system_prompt;
      name = None;
      tool_calls = None };
    { role = User;
      content = user_prompt;
      name = None;
      tool_calls = None };
  ] in
  (* Stdio.print_endline (Printf.sprintf "Sending messages to Claude: %s" (String.concat "\n" (List.map (fun m -> m.content) messages))); *)
  let%lwt result = ClaudeClient.complete client ~messages () in
  match result with
  | Ok response -> 
      Lwt.return (Ok response.text)
  | Error e -> 
      Lwt.return (Error (string_of_error e)) 