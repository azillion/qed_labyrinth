open Retry_utils

module type ProviderLimits = sig
  val requests_per_minute: int
  val tokens_per_minute: int
  val max_parallel_requests: int
  val retry_strategy: retry_strategy
end

module OpenAILimits = struct
  let requests_per_minute = 60
  let tokens_per_minute = 90_000
  let max_parallel_requests = 10
  let retry_strategy = FullJitter {
    base = 2.0;
    max_delay = 32.0;
  }
end

module ClaudeLimits = struct
  let requests_per_minute = 50
  let tokens_per_minute = 100_000
  let max_parallel_requests = 5
  let retry_strategy = Exponential {
    base = 1.5;
    max_delay = 60.0;
  }
end

module DeepseekLimits = struct
  let requests_per_minute = 40
  let tokens_per_minute = 80_000
  let max_parallel_requests = 5
  let retry_strategy = Exponential {
    base = 2.0;
    max_delay = 45.0;
  }
end