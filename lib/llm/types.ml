type role =
  | System
  | User 
  | Assistant
  | Function
  | Tool

let string_of_role = function
  | System -> "system"
  | User -> "user"
  | Assistant -> "assistant"
  | Function -> "function"
  | Tool -> "tool"

let role_of_string = function
  | "system" -> System
  | "user" -> User
  | "assistant" -> Assistant
  | "function" -> Function
  | "tool" -> Tool
  | s -> failwith ("Unknown role: " ^ s)

type tool_call = {
  id: string;
  tool_type: string;  (* "function" etc *)
  name: string;
  arguments: string;
}

type message = {
  role: role;
  content: string;
  name: string option;  (* for function/tool calls *)
  tool_calls: tool_call list option;
}

type error =
  | NetworkError of string
  | JsonError of string
  | HttpError of int * string 
  | ValidationError of string
  | RateLimitError
  | AuthError
  | RetryError of error * int  (* original error and attempt count *)

let rec string_of_error = function
  | NetworkError msg -> Printf.sprintf "Network error: %s" msg
  | JsonError msg -> Printf.sprintf "JSON error: %s" msg
  | HttpError (code, msg) -> Printf.sprintf "HTTP %d: %s" code msg
  | ValidationError msg -> Printf.sprintf "Validation error: %s" msg
  | RateLimitError -> "Rate limit exceeded"
  | AuthError -> "Authentication failed"
  | RetryError (e, attempts) -> 
      Printf.sprintf "Failed after %d attempts: %s" attempts (string_of_error e)

(* type completion_chunk = {
  text: string;
  finish_reason: string option;
} *)

type usage = {
  prompt_tokens: int;
  completion_tokens: int;
  total_tokens: int;
}

type response = {
    text: string;
    finish_reason: string option;
    usage: usage option;
}