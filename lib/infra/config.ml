open Base

let getenv_default var default = try Sys.getenv_exn var with _ -> default

module Database : sig
  type t = {
    db_path : string;
  }

  val create :
    ?db_path:string ->
    unit ->
    t

  val from_env : unit -> t
  val to_uri : t -> Uri.t
end = struct
  type t = {
    db_path : string;
  }

  let create ?(db_path="qed_labyrinth.sqlite3") () =
    { db_path }

  let from_env () =
    let db_path = getenv_default "QED_DATABASE_PATH" "qed_labyrinth.sqlite3" in
    { db_path }

  let to_uri t =
    Uri.make ~scheme:"sqlite3" ~path:t.db_path ()
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
