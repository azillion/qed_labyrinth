open Types

module type Provider = sig
    type config
    type request_options
  
    val default_options : request_options

    val create_config :
      api_key:string ->
      ?model:string ->
      ?base_url:string ->
      ?organization_id:string ->
      unit -> config
  
    val complete : 
      config:config ->
      ?options:request_options ->
      messages:message list ->
      unit ->
      (Types.response, error) result Lwt.t
  
    (* val complete_stream :
      config:config ->
      ?options:request_options ->
      messages:Types.message list ->
      (Types.completion_chunk -> unit) ->
      unit ->
      (unit, error) result Lwt.t *)
      
    val validate_messages : Types.message list -> (unit, error) result
    val validate_options : request_options -> (unit, error) result
end