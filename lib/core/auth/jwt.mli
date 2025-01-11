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

val generate_token : string -> (string, [> error]) result
val verify_token : string -> (string, [> error]) result