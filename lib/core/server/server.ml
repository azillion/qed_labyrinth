open Base

type app_state = {
  connection_manager : Connection_manager.t;
  db_pool : Qed_labyrinth_core.Db.Pool.t;
  game_state : Game.State.t;
}

let create_app_state db_pool = {
  connection_manager = Connection_manager.create ();
  db_pool;
  game_state = Game.State.create;
}

let cors_middleware inner_handler request =
  match Dream.method_ request with
  | `OPTIONS ->
      Dream.respond ~headers:[
        "Access-Control-Allow-Origin", "*";
        "Access-Control-Allow-Methods", "GET, POST, OPTIONS";
        "Access-Control-Allow-Headers", "Content-Type, Authorization"
      ] ""
  | _ ->
      let%lwt response = inner_handler request in
      Dream.add_header response "Access-Control-Allow-Origin" "*";
      Lwt.return response

let start pool =
  let open Game in
  let app_state = create_app_state pool in
  (* Start game loop *)
  Lwt.async (fun () -> Loop.run app_state.game_state);

  (* Configure web server *)
  Dream.run ~interface:"0.0.0.0" ~port:3030
  @@ Dream.logger
  @@ cors_middleware
  @@ Dream.router
       [ 
        Dream.options "/auth/**" (fun _ -> 
          Dream.respond ~headers:[
            "Access-Control-Allow-Origin", "*";
            "Access-Control-Allow-Methods", "GET, POST, OPTIONS";
            "Access-Control-Allow-Headers", "Content-Type, Authorization"
          ] "");
(*           
        Dream.post "/auth/login" (fun request ->
          let%lwt body = Dream.body request in
          match Yojson.Safe.from_string body with
          | exception _ -> 
              Dream.json ~status:`Bad_Request
                (Yojson.Safe.to_string 
                  (`Assoc [("error", `String "Invalid JSON")]))
          | body_json -> handle_login ~db request body_json);
    
        Dream.post "/auth/register" (fun request ->
          let%lwt body = Dream.body request in
          match Yojson.Safe.from_string body with
          | exception _ -> 
              Dream.json ~status:`Bad_Request
                (Yojson.Safe.to_string 
                  (`Assoc [("error", `String "Invalid JSON")]))
          | body_json -> handle_register ~db body_json);
    
        Dream.get "/auth/verify" (fun request -> handle_verify ~db request); *)

        Dream.get "/websocket" (fun _ -> Dream.websocket (Websocket_handler.handler app_state.connection_manager))
      ]
