open Provider
open Provider_limits
open Rate_limit

module Make(P: Provider)(L: ProviderLimits) = struct
  type t = {
    config: P.config;
    default_options: P.request_options;
    request_limiter: TokenBucket.t;
    token_limiter: TokenBucket.t;
    request_pool: unit Lwt_pool.t;
  }

  let create ?(options=P.default_options) config =
    {
      config;
      default_options = options;
      request_limiter = TokenBucket.create
        ~capacity:(L.requests_per_minute / 2)
        ~refill_rate:(float_of_int L.requests_per_minute /. 60.0)
        ~burst_capacity:L.requests_per_minute;
      token_limiter = TokenBucket.create
        ~capacity:(L.tokens_per_minute / 2)
        ~refill_rate:(float_of_int L.tokens_per_minute /. 60.0)
        ~burst_capacity:L.tokens_per_minute;
      request_pool = Lwt_pool.create 
        L.max_parallel_requests
        (fun () -> Lwt.return_unit);
    }

  let complete ?options t ~messages () =
    let module Prov = P in
    let estimated_tokens = Token_utils.estimate_tokens messages in
    
    let%lwt request_token = TokenBucket.acquire t.request_limiter in
    match request_token with
    | Error (`WaitNeeded _) -> Lwt.return_error Types.RateLimitError
    | Ok () ->
        let%lwt token_count = TokenBucket.acquire ~cost:(float_of_int estimated_tokens) t.token_limiter in
        match token_count with
        | Error (`WaitNeeded _) -> Lwt.return_error Types.RateLimitError
        | Ok () ->
            let%lwt result = Lwt_pool.use t.request_pool (fun () ->
              Retry_utils.with_retries
                ~max_attempts:3
                ~strategy:L.retry_strategy
                ~on_retry:(fun attempt delay error ->
                  Lwt_io.printf "Attempt %d failed: %s. Retrying in %.1fs\n"
                    attempt (Types.string_of_error error) delay)
                (fun () -> Prov.complete ~config:t.config ?options ~messages ())
                1
            ) in
            match result with
            | Ok result -> Lwt.return_ok result
            | Error (`MaxAttemptsExceeded n) -> Lwt.return_error (Types.NetworkError (Printf.sprintf "Max attempts (%d) exceeded" n))
            | Error (`OtherError e) -> Lwt.return e
end