(** Application configuration *)

let getenv_default var default =
  try Sys.getenv var with Not_found -> default

module Database = struct
  type t = {
    host : string;
    port : int;
    user : string;
    password : string;
    dbname : string;
  }

  let create
      ?(host = "localhost")
      ?(port = 5432)
      ?(user = "postgres")
      ?(password = "")
      ?(dbname = "qed_labyrinth")
      () =
    { host; port; user; password; dbname }

  let from_env () =
    let host = getenv_default "QED_DB_HOST" "localhost" in
    let port = getenv_default "QED_DB_PORT" "5432" |> int_of_string in
    let user = getenv_default "QED_DB_USER" "postgres" in
    let password = getenv_default "QED_DB_PASSWORD" "" in
    let dbname = getenv_default "QED_DB_NAME" "qed_labyrinth" in
    { host; port; user; password; dbname }

  let to_uri t =
    let userinfo =
      if t.password = "" then t.user
      else t.user ^ ":" ^ t.password
    in
    Uri.make
      ~scheme:"postgresql"
      ~userinfo
      ~host:t.host
      ~port:t.port
      ~path:("/" ^ t.dbname)
      ()
end

module Redis = struct
  type t = {
    host : string;
    port : int;
  }

  let create ?(host = "127.0.0.1") ?(port = 6379) () =
    { host; port }

  let from_env () =
    let host = getenv_default "REDIS_HOST" "127.0.0.1" in
    let port = getenv_default "REDIS_PORT" "6379" |> int_of_string in
    { host; port }

  let to_redis_config t : Redis.config =
    { Redis.host = t.host; port = t.port }
end

type t = {
  database : Database.t;
  redis : Redis.t;
  server_port : int;
  server_interface : string;
}

let create
    ?(database = Database.create ())
    ?(redis = Redis.create ())
    ?(server_port = 3030)
    ?(server_interface = "0.0.0.0")
    () =
  { database; redis; server_port; server_interface }

let load () =
  let database = Database.from_env () in
  let redis = Redis.from_env () in
  let server_port = getenv_default "QED_SERVER_PORT" "3030" |> int_of_string in
  let server_interface = getenv_default "QED_SERVER_INTERFACE" "0.0.0.0" in
  { database; redis; server_port; server_interface }
