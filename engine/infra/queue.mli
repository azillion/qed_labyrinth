(** A generic queue type parameterized by the type of elements it contains *)
type 'a t

(** Create a new empty queue *)
val create : unit -> 'a t

(** Push a new element to the queue *)
val push : 'a t -> 'a -> unit Lwt.t

(** Try to pop an element from the queue, returning None if the queue is empty *)
val pop_opt : 'a t -> 'a option Lwt.t