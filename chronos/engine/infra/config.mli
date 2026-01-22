(** Application configuration *)

(** Get environment variable with a default value *)
val getenv_default : string -> string -> string

(** Database configuration *)
module Database : sig
  type t = {
    host : string;
    port : int;
    user : string;
    password : string;
    dbname : string;
  }

  (** Create a database config with optional parameters *)
  val create :
    ?host:string ->
    ?port:int ->
    ?user:string ->
    ?password:string ->
    ?dbname:string ->
    unit ->
    t

  (** Load database config from environment variables:
      - QED_DB_HOST (default: localhost)
      - QED_DB_PORT (default: 5432)
      - QED_DB_USER (default: postgres)
      - QED_DB_PASSWORD (default: "")
      - QED_DB_NAME (default: qed_labyrinth)
  *)
  val from_env : unit -> t

  (** Convert config to a PostgreSQL URI *)
  val to_uri : t -> Uri.t
end

(** Redis configuration *)
module Redis : sig
  type t = {
    host : string;
    port : int;
  }

  (** Create a Redis config with optional parameters *)
  val create : ?host:string -> ?port:int -> unit -> t

  (** Load Redis config from environment variables:
      - REDIS_HOST (default: 127.0.0.1)
      - REDIS_PORT (default: 6379)
  *)
  val from_env : unit -> t

  (** Convert to the Redis module's config type *)
  val to_redis_config : t -> Redis.config
end

(** Full application configuration *)
type t = {
  database : Database.t;
  redis : Redis.t;
  server_port : int;
  server_interface : string;
}

(** Create a full config with optional parameters *)
val create :
  ?database:Database.t ->
  ?redis:Redis.t ->
  ?server_port:int ->
  ?server_interface:string ->
  unit ->
  t

(** Load full config from environment variables *)
val load : unit -> t
