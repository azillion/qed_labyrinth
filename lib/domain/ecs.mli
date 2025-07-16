open Base

module Entity : sig
  type t = Uuidm.t  (* Expose underlying type to allow seamless use with Uuidm.t *)
  (** Ensure an entity with the given id exists, inserting it if necessary. *)
  val ensure_exists : t -> (unit, Base.Error.t) Result.t Lwt.t
end

(** Signature for all component storage modules that the ECS exposes. *)
module type ComponentStorage = sig
  type component
  val set : Entity.t -> component -> unit Lwt.t
  val get : Entity.t -> component option Lwt.t
  val remove : Entity.t -> unit Lwt.t
  val all : unit -> (Entity.t * component) list Lwt.t
  val sync_to_db : (module Caqti_lwt.CONNECTION) -> (unit, 'err) Result.t Lwt.t
  val load_from_db : unit -> unit Lwt.t
  val clear_modified : unit -> unit
  val get_modified : unit -> Entity.t list
end

module CharacterStorage          : ComponentStorage with type component = Components.CharacterComponent.t
module CharacterPositionStorage  : ComponentStorage with type component = Components.CharacterPositionComponent.t
module CoreStatsStorage          : ComponentStorage with type component = Components.CoreStatsComponent.t
module DerivedStatsStorage       : ComponentStorage with type component = Components.DerivedStatsComponent.t
module HealthStorage             : ComponentStorage with type component = Components.HealthComponent.t
module ActionPointsStorage       : ComponentStorage with type component = Components.ActionPointsComponent.t
module ItemStorage               : ComponentStorage with type component = Components.ItemComponent.t
module InventoryStorage          : ComponentStorage with type component = Components.InventoryComponent.t
module ItemPositionStorage       : ComponentStorage with type component = Components.ItemPositionComponent.t
module UnconsciousStorage        : ComponentStorage with type component = Unconscious_component.t

(** {2 World functions} *)
module World : sig
  module StorageRegistry : sig
    val get_all_modified_components : unit -> Set.M(String).t
    val clear_all_modified : unit -> unit
  end

  val step : unit -> unit Lwt.t
  val init : Redis_lwt.Client.connection -> (unit, Base.Error.t) Result.t Lwt.t
  val sync_to_db : unit -> unit Lwt.t
end 