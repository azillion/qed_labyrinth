module TokenBucket = struct
  type t = {
    capacity: int;
    burst_capacity: int;  (* Allow temporary bursts *)
    mutable tokens: float;  (* Use float for fractional tokens *)
    refill_rate: float;    (* tokens per second *)
    mutable last_refill: float;
    mutex: Lwt_mutex.t;
  }

  let create ~capacity ~refill_rate ~burst_capacity = {
    capacity;
    burst_capacity = max capacity burst_capacity;
    tokens = float_of_int capacity;
    refill_rate;
    last_refill = Unix.gettimeofday ();
    mutex = Lwt_mutex.create ();
  }

  let refill bucket =
    let now = Unix.gettimeofday () in
    let elapsed = now -. bucket.last_refill in
    let new_tokens = min 
      (float_of_int bucket.burst_capacity)
      (bucket.tokens +. (elapsed *. bucket.refill_rate))
    in
    bucket.tokens <- new_tokens;
    bucket.last_refill <- now

  let acquire ?(cost=1.0) bucket =
    Lwt_mutex.with_lock bucket.mutex (fun () ->
      refill bucket;
      if bucket.tokens >= cost then begin
        bucket.tokens <- bucket.tokens -. cost;
        Lwt.return_ok ()
      end else
        let wait_time = (cost -. bucket.tokens) /. bucket.refill_rate in
        Lwt.return_error (`WaitNeeded wait_time)
    )
end