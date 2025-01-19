type error = [
    | `InvalidAlgorithm
    | `InvalidFormat 
    | `MissingKey
    | `InvalidSignature
    | `Expired
    | `MissingClaim
    | `Not_json
    | `Invalid_supported
    | `Msg of string
]

let secret = "your-shared-secret-make-this-secure"

let generate_token user_id =
    let header = Jose.Header.make_header ~typ:"JWT" (Jose.Jwk.make_oct secret) in
    let now = Ptime_clock.now () in
    let exp = Ptime.add_span now (Ptime.Span.of_int_s (60 * 60 * 24)) in (* 24 hours *)
    let payload = 
      Jose.Jwt.empty_payload
      |> Jose.Jwt.add_claim "sub" (`String user_id)
      |> Jose.Jwt.add_claim "exp" (`Int (
        match exp with
        | Some t -> Int.of_float (Ptime.to_float_s t)
        | None -> Int.of_float (Ptime.to_float_s now)
      ))
    in
    let jwt = Jose.Jwt.sign ~header ~payload (Jose.Jwk.make_oct secret) in
    match jwt with
    | Ok jwt -> Ok (Jose.Jwt.to_string jwt)
    | Error e -> Error e
  
    let verify_token token =
      let jwk = Jose.Jwk.make_oct secret |> Jose.Jwk.pub_of_priv in
      let now = Ptime_clock.now () in
      match Jose.Jwt.of_string ~jwk ~now token with
      | Ok jwt -> 
          (match Jose.Jwt.get_string_claim jwt "sub" with
           | Some user_id -> Ok user_id
           | None -> Error `MissingClaim)
      | Error e ->
        match e with
        | `Invalid_signature -> Error `InvalidSignature
        | `Expired -> Error `Expired
        | `Invalid_format -> Error `InvalidFormat
        | `Invalid_algorithm -> Error `InvalidAlgorithm
        | `Invalid_json -> Error `Not_json
        | `Msg msg -> Error (`Msg msg)
        | _ -> Error (`Msg "Unknown error")
