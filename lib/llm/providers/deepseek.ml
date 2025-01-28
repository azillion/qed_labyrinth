open Provider
open Types

module Deepseek : Provider = struct
  type config = {
    api_key: string;
    base_url: string;
    organization_id: string option;
    model: string;
  }

  type request_options = {
    temperature: float option;
    max_tokens: int option;
    stream: bool option;
    stop: string list option;
    top_p: float option;
    frequency_penalty: float option;
    presence_penalty: float option;
  }

  let default_options = {
    temperature = Some 0.7;
    max_tokens = Some 1000;
    stream = None;
    stop = None;
    top_p = None;
    frequency_penalty = None;
    presence_penalty = None;
  }

  let create_config ~api_key ?model ?base_url ?organization_id () = {
    api_key;
    base_url = Option.value base_url ~default:"https://api.deepseek.com/v1";
    organization_id;
    model = Option.value model ~default:"deepseek-chat";
  }

  let make_headers config = 
    let headers = Cohttp.Header.init () in
    let headers = Cohttp.Header.add headers "Authorization" ("Bearer " ^ config.api_key) in
    let headers = Cohttp.Header.add headers "Content-Type" "application/json" in
    match config.organization_id with
    | Some org_id -> Cohttp.Header.add headers "Deepseek-Organization" org_id
    | None -> headers

  let to_deepseek_messages messages =
    `List (List.map (fun msg ->
      `Assoc [
        ("role", `String (string_of_role msg.role));
        ("content", `String msg.content)
      ]
    ) messages)

  let make_request_body ~config  ~messages options =
    let base = [
      ("model", `String config.model);
      ("messages", to_deepseek_messages messages)
    ] in
    let with_options = List.filter_map (fun (key, value) -> value |> Option.map (fun v -> (key, v))) [
      "temperature", options.temperature |> Option.map (fun t -> `Float t);
      "max_tokens", options.max_tokens |> Option.map (fun t -> `Int t);
      "stream", options.stream |> Option.map (fun s -> `Bool s);
      "stop", options.stop |> Option.map (fun s -> `List (List.map (fun x -> `String x) s));
      "top_p", options.top_p |> Option.map (fun t -> `Float t);
      "frequency_penalty", options.frequency_penalty |> Option.map (fun f -> `Float f);
      "presence_penalty", options.presence_penalty |> Option.map (fun p -> `Float p)
    ] in
    `Assoc (base @ with_options)

  let parse_response body =
    try
      let json = Yojson.Basic.from_string body in
      let open Yojson.Basic.Util in
      let choices = json |> member "choices" |> to_list in
      match choices with
      | choice :: _ ->
          let message = choice |> member "message" in
          let content = message |> member "content" |> to_string in
          let finish_reason = 
            try Some (choice |> member "finish_reason" |> to_string)
            with _ -> None
          in
          let usage = 
            try
              let u = json |> member "usage" in
              Some {
                prompt_tokens = u |> member "prompt_tokens" |> to_int;
                completion_tokens = u |> member "completion_tokens" |> to_int;
                total_tokens = u |> member "total_tokens" |> to_int
              }
            with _ -> None
          in
          Ok { text = content; finish_reason; usage }
      | [] -> Error (JsonError "No choices in response")
    with 
    | Yojson.Json_error msg -> Error (JsonError msg)
    | e -> Error (JsonError (Printexc.to_string e))

  let complete ~config ?(options=default_options) ~messages () : (response, error) result Lwt.t =
    let uri = Uri.of_string (config.base_url ^ "/chat/completions") in
    let headers = make_headers config in
    let body = make_request_body ~config ~messages options |> Yojson.Basic.to_string in
    
    let%lwt result = Http_client.post_request ~headers ~body:(Some body) uri in
    match result with
    | Ok response_body -> Lwt.return (parse_response response_body)
    | Error (Http_client.ConnectionError msg) -> Lwt.return_error (NetworkError msg)
    | Error Http_client.TimeoutError -> Lwt.return_error (NetworkError "Request timed out")
    | Error (Http_client.ResponseError (code, msg)) -> Lwt.return_error (HttpError (code, msg))

  let validate_messages messages =
    if List.length messages = 0 then
      Error (ValidationError "Must provide at least one message")
    else if List.exists (fun msg -> String.length msg.content = 0) messages then
      Error (ValidationError "Message content cannot be empty")
    else
      Ok ()

  let validate_options options =
    let validate_temp = match options.temperature with
      | Some t when t < 0.0 || t > 2.0 ->
          Error "Temperature must be between 0 and 2"
      | _ -> Ok ()
    in
    let validate_top_p = match options.top_p with
      | Some p when p < 0.0 || p > 1.0 ->
          Error "Top_p must be between 0 and 1"
      | _ -> Ok ()
    in
    match validate_temp, validate_top_p with
    | Ok (), Ok () -> Ok ()
    | Error e, _ | _, Error e -> Error (ValidationError e)
end