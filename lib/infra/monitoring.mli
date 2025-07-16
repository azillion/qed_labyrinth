(** Observability tools for logging, metrics, and tracing. *)

module Metrics : sig
  (** Increment a counter. Creates it if it doesn't exist. *)
  val inc : string -> unit

  (** Set a gauge value. *)
  val set_gauge : string -> float -> unit

  (** Record a duration in seconds for a histogram-like value.
      For now, it just records the sum and count. *)
  val observe_duration : string -> float -> unit

  (** Get all metrics as a Yojson object. *)
  val to_yojson : unit -> Yojson.Safe.t
end

module Log : sig
  type level = Debug | Info | Warn | Error

  (** Low-level log function. *)
  val log : level -> string -> (string * string) list -> unit Lwt.t

  (** Log a debug message. *)
  val debug : string -> ?data:(string * string) list -> unit -> unit Lwt.t

  (** Log an info message. *)
  val info : string -> ?data:(string * string) list -> unit -> unit Lwt.t

  (** Log a warning message. *)
  val warn : string -> ?data:(string * string) list -> unit -> unit Lwt.t

  (** Log an error message. *)
  val error : string -> ?data:(string * string) list -> unit -> unit Lwt.t
end 