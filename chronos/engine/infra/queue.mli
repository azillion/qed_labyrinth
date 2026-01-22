(** A generic unbounded queue for Eio-based concurrency *)

(** A queue parameterized by element type *)
type 'a t

(** Create a new empty queue with the specified capacity (0 for unbounded) *)
val create : ?capacity:int -> unit -> 'a t

(** Push a new element to the queue. 
    If the queue has reached capacity, this will block until space is available. *)
val push : 'a t -> 'a -> unit

(** Try to pop an element from the queue without blocking.
    Returns None if the queue is empty. *)
val pop_opt : 'a t -> 'a option

(** Pop an element from the queue, blocking if empty *)
val pop : 'a t -> 'a

(** Check if the queue is empty *)
val is_empty : 'a t -> bool
