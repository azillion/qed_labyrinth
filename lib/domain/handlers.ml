let all_client_handlers : (module Client_handler.S) list =
  [ (module Character_handler.Handler); (module Communication_handler.Handler) ]
