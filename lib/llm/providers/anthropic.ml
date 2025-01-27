open Provider
open Types

module Anthropic : Provider = struct
  type config = {
    api_key: string;
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

  let create_config ~api_key ?model ?base_url:_ ?organization_id:_ () = {
    api_key;
    model = Option.value model ~default:"claude-2.1";
  }

  let make_headers config =
    let headers = Cohttp.Header.init () in
    let headers = Cohttp.Header.add headers "x-api-key" config.api_key in
    let headers = Cohttp.Header.add headers "anthropic-version" "2023-06-01" in
    Cohttp.Header.add headers "content-type" "application/json"

    let to_claude_messages messages =
      let rec format_messages acc = function
        | [] -> acc
        | msg :: rest ->
            let formatted = match msg.role with
              | System -> 
                  Printf.sprintf "\n\nHuman: %s\n\nAssistant: I understand." msg.content
              | User -> 
                  Printf.sprintf "\n\nHuman: %s" msg.content
              | Assistant ->
                  Printf.sprintf "\n\nAssistant: %s" msg.content
              | _ -> failwith "Unsupported role for Claude"
            in
            format_messages (acc ^ formatted) rest
      in
      let base = format_messages "" messages in
      (* Claude requires prompt to end with Assistant turn *)
      if String.ends_with ~suffix:"\n\nAssistant:" base then
        base
      else
        base ^ "\n\nAssistant:"

  let make_request_body ~config ~messages options =
    let prompt = to_claude_messages messages in
    let base = [
      ("model", `String config.model);
      ("prompt", `String prompt)
    ] in
    let with_options = List.filter_map (fun (key, value) -> value |> Option.map (fun v -> (key, v))) [
      "temperature", options.temperature |> Option.map (fun t -> `Float t);
      "max_tokens_to_sample", options.max_tokens |> Option.map (fun t -> `Int t);
      "stream", options.stream |> Option.map (fun s -> `Bool s);
      "stop_sequences", options.stop |> Option.map (fun s -> `List (List.map (fun x -> `String x) s));
      "top_p", options.top_p |> Option.map (fun t -> `Float t)
    ] in
    `Assoc (base @ with_options)

  let parse_response body =
    try
      let json = Yojson.Basic.from_string body in
      let open Yojson.Basic.Util in
      let completion = json |> member "completion" |> to_string in
      let finish_reason = 
        try Some (json |> member "stop_reason" |> to_string)
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
      Ok { text = completion; finish_reason; usage }
    with
    | Yojson.Json_error msg -> Error (JsonError msg)
    | e -> Error (JsonError (Printexc.to_string e))

  let complete ~config ?(options=default_options) ~messages () =
    let uri = Uri.of_string "https://api.anthropic.com/v1/complete" in
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
    else
      Ok ()

  let validate_options options =
    match options.temperature with
    | Some t when t < 0.0 || t > 1.0 ->
        Error (ValidationError "Temperature must be between 0 and 1")
    | _ -> Ok ()
end