module type Frame = sig
  type t
  val empty : t
  val of_character : Character.t -> t
end