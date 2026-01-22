(** Eio-based Redis client *)

type config = {
  host : string;
  port : int;
}

(* Use a module to hide the socket type *)
module type FLOW = sig
  val read : Eio.Buf_read.t
  val write : string -> unit
  val close : unit -> unit
end

type connection = {
  flow_module : (module FLOW);
  mutable closed : bool;
}

exception Redis_error of string

let connect ~sw ~net config =
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, config.port) in
  let addr = 
    if config.host = "127.0.0.1" || config.host = "localhost" then
      addr
    else
      (* Resolve hostname *)
      match Eio.Net.getaddrinfo_stream net config.host ~service:(string_of_int config.port) with
      | [] -> failwith (Printf.sprintf "Could not resolve host: %s" config.host)
      | addr :: _ -> addr
  in
  let socket = Eio.Net.connect ~sw net addr in
  let reader = Eio.Buf_read.of_flow ~max_size:1_000_000 socket in
  let module F = struct
    let read = reader
    let write s = Eio.Flow.copy_string s socket
    let close () = Eio.Flow.close socket
  end in
  { flow_module = (module F); closed = false }

let close conn =
  if not conn.closed then begin
    conn.closed <- true;
    let module F = (val conn.flow_module : FLOW) in
    F.close ()
  end

(** Send a command and read the response *)
let command conn args =
  if conn.closed then raise (Redis_error "Connection closed");
  let module F = (val conn.flow_module : FLOW) in
  let cmd = Resp.encode_command args in
  F.write cmd;
  let response = Resp.decode F.read in
  match Resp.error_message response with
  | Some msg -> raise (Redis_error msg)
  | None -> response

(** Send a command without waiting for response (used after SUBSCRIBE) *)
let send_command conn args =
  if conn.closed then raise (Redis_error "Connection closed");
  let module F = (val conn.flow_module : FLOW) in
  let cmd = Resp.encode_command args in
  F.write cmd

(* String Commands *)

let get conn key =
  let resp = command conn ["GET"; key] in
  Resp.to_string_opt resp

let set conn key value =
  let resp = command conn ["SET"; key; value] in
  match resp with
  | Resp.Simple_string "OK" -> ()
  | _ -> raise (Redis_error "Unexpected response from SET")

(* Hash Commands *)

let hset conn key field value =
  let resp = command conn ["HSET"; key; field; value] in
  match Resp.to_int_opt resp with
  | Some n -> n
  | None -> raise (Redis_error "Unexpected response from HSET")

let hget conn key field =
  let resp = command conn ["HGET"; key; field] in
  Resp.to_string_opt resp

let hdel conn key field =
  let resp = command conn ["HDEL"; key; field] in
  match Resp.to_int_opt resp with
  | Some n -> n
  | None -> raise (Redis_error "Unexpected response from HDEL")

let hmset conn key fields =
  if fields = [] then ()
  else begin
    let args = ["HMSET"; key] @ List.concat_map (fun (f, v) -> [f; v]) fields in
    let resp = command conn args in
    match resp with
    | Resp.Simple_string "OK" -> ()
    | _ -> raise (Redis_error "Unexpected response from HMSET")
  end

let hgetall conn key =
  let resp = command conn ["HGETALL"; key] in
  match Resp.to_array_opt resp with
  | None -> []
  | Some arr ->
      let rec pairs acc = function
        | [] -> List.rev acc
        | k :: v :: rest ->
            (match Resp.to_string_opt k, Resp.to_string_opt v with
            | Some ks, Some vs -> pairs ((ks, vs) :: acc) rest
            | _ -> pairs acc rest)
        | _ -> List.rev acc
      in
      pairs [] arr

(* Key Commands *)

let del conn keys =
  if keys = [] then 0
  else begin
    let resp = command conn ("DEL" :: keys) in
    match Resp.to_int_opt resp with
    | Some n -> n
    | None -> raise (Redis_error "Unexpected response from DEL")
  end

(* Pub/Sub Commands *)

let publish conn channel message =
  let resp = command conn ["PUBLISH"; channel; message] in
  match Resp.to_int_opt resp with
  | Some n -> n
  | None -> raise (Redis_error "Unexpected response from PUBLISH")

let subscribe conn channels =
  if channels = [] then ()
  else begin
    send_command conn ("SUBSCRIBE" :: channels);
    let module F = (val conn.flow_module : FLOW) in
    (* Read subscription confirmations *)
    List.iter (fun _ ->
      let _ = Resp.decode F.read in
      ()
    ) channels
  end

type pubsub_message =
  | Message of { channel : string; payload : string }
  | Subscribe of { channel : string; count : int }
  | Unsubscribe of { channel : string; count : int }
  | Other of Resp.value

let read_message conn =
  let module F = (val conn.flow_module : FLOW) in
  let resp = Resp.decode F.read in
  match Resp.to_array_opt resp with
  | Some [kind; channel; data] ->
      (match Resp.to_string_opt kind, Resp.to_string_opt channel with
      | Some "message", Some ch ->
          (match Resp.to_string_opt data with
          | Some payload -> Message { channel = ch; payload }
          | None -> Other resp)
      | Some "subscribe", Some ch ->
          (match Resp.to_int_opt data with
          | Some count -> Subscribe { channel = ch; count }
          | None -> Other resp)
      | Some "unsubscribe", Some ch ->
          (match Resp.to_int_opt data with
          | Some count -> Unsubscribe { channel = ch; count }
          | None -> Other resp)
      | _ -> Other resp)
  | _ -> Other resp
