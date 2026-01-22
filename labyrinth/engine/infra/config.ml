open Base

let getenv_default var default = try Sys.getenv_exn var with _ -> default

module Database : sig
  type t = {
    host : string;
    port : int;
    user : string;
    password : string;
    dbname : string;
  }

  val create :
    ?host:string ->
    ?port:int ->
    ?user:string ->
    ?password:string ->
    ?dbname:string ->
    unit ->
    t

  val from_env : unit -> t
  val to_uri : t -> Uri.t
end = struct
  type t = {
    host : string;
    port : int;
    user : string;
    password : string;
    dbname : string;
  }

  let create ?(host="localhost") ?(port=5432) ?(user="postgres") ?(password="") ?(dbname="qed_labyrinth") () =
    { host; port; user; password; dbname }

  let from_env () =
    let host = getenv_default "QED_DB_HOST" "localhost" in
    let port = getenv_default "QED_DB_PORT" "5432" |> Int.of_string in
    let user = getenv_default "QED_DB_USER" "postgres" in
    let password = getenv_default "QED_DB_PASSWORD" "" in
    let dbname = getenv_default "QED_DB_NAME" "qed_labyrinth" in
    { host; port; user; password; dbname }

  let to_uri t =
    let userinfo = if String.is_empty t.password then t.user else t.user ^ ":" ^ t.password in
    Uri.make ~scheme:"postgresql" ~userinfo ~host:t.host ~port:t.port ~path:("/" ^ t.dbname) ()
end

type t = { database : Database.t; server_port : int; server_interface : string }

let create ?(database = Database.create ()) ?(server_port = 3030)
    ?(server_interface = "0.0.0.0") () =
  { database; server_port; server_interface }

let load () =
  let database = Database.from_env () in
  let server_port = getenv_default "QED_SERVER_PORT" "3030" |> Int.of_string in
  let server_interface = getenv_default "QED_SERVER_INTERFACE" "0.0.0.0" in
  { database; server_port; server_interface }
