open Types

type retry_strategy =
  | Constant of float
  | Linear of float
  | Exponential of {base: float; max_delay: float}
  | FullJitter of {base: float; max_delay: float}

let calculate_delay strategy attempt =
  match strategy with
  | Constant delay -> delay
  | Linear base -> base *. float_of_int attempt
  | Exponential {base; max_delay} ->
      min max_delay (base ** float_of_int attempt)
  | FullJitter {base; max_delay} ->
      let exp_delay = min max_delay (base ** float_of_int attempt) in
      Random.float exp_delay

let should_retry error attempt max_attempts =
  attempt <= max_attempts &&
  match error with
  | NetworkError _ | RateLimitError -> true
  | HttpError (code, _) -> code >= 500 || code = 429
  | _ -> false

let rec with_retries ~max_attempts ~strategy ~on_retry f attempt =
  let open Lwt in
  if attempt > max_attempts then
    Lwt.return_error (`MaxAttemptsExceeded attempt)
  else
    f () >>= function
    | Ok x -> Lwt.return_ok x
    | Error e as err ->
        if should_retry e attempt max_attempts then
          let delay = calculate_delay strategy attempt in
          on_retry attempt delay e >>= fun () ->
          Lwt_unix.sleep delay >>= fun () ->
          with_retries ~max_attempts ~strategy ~on_retry f (attempt + 1)
        else
          Lwt.return_error (`OtherError err)