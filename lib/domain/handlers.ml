let all_client_handlers : (module Client_handler.S) list =
  [
    (module Area_handler.Handler);
    (module Character_handler.Handler);
    (module Communication_handler.Handler);
    (module World_handler.Handler);
  ]