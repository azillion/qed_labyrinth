open Base

(* lib/config/config.ml *)
let getenv_default var default =
  try Sys.getenv_exn var
  with _ -> default

module Database = struct
  type t = {
    name: string;
    host: string;
    port: int;
    user: string;
    password: string;
  }

  let create 
    ?(name="qed_labyrinth")
    ?(host="localhost") 
    ?(port=5432)
    ?(user="postgres")
    ?(password="postgres") 
    () = 
    {name; host; port; user; password}

    
  let from_env () =
    {
      name = getenv_default "QED_DB_NAME" "qed_labyrinth";
      host = getenv_default "QED_DB_HOST" "localhost";
      port = getenv_default "QED_DB_PORT" "5432" |> Int.of_string;
      user = getenv_default "QED_DB_USER" "postgres";
      password = getenv_default "QED_DB_PASSWORD" "postgres";
    }

  let to_uri t =
    Uri.make 
      ~scheme:"postgresql" 
      ~host:t.host 
      ~port:t.port 
      ~userinfo:(t.user ^ ":" ^ t.password)
      ~path:("/" ^ t.name) 
      ()
end

type t = {
  database: Database.t;
  server_port: int;
  server_interface: string;
}

let create 
  ?(database=Database.create ()) 
  ?(server_port=3030)
  ?(server_interface="0.0.0.0")
  () =
  {database; server_port; server_interface}

let load () =
  let database = Database.from_env () in
  let server_port = 
    getenv_default "QED_SERVER_PORT" "3030"
    |> Int.of_string 
  in
  let server_interface = 
    getenv_default "QED_SERVER_INTERFACE" "0.0.0.0"
  in
  {database; server_port; server_interface}
