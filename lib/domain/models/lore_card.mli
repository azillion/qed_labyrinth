open Base

module Template : sig
  type t = {
    id : string;
    card_name : string;
    power_cost : int;
    required_saga_tier : int;
    default_title : string option;
    default_description : string option;
    bonus_1_type : string option;
    bonus_1_value : int option;
    bonus_2_type : string option;
    bonus_2_value : int option;
    bonus_3_type : string option;
    bonus_3_value : int option;
    grants_ability : string option;
  }
end

module Instance : sig
  type t = {
    id : string;
    character_id : string;
    template_id : string;
    title : string;
    description : string;
    is_active : bool;
  }
end

val create_instance :
  character_id:string ->
  template_id:string ->
  title:string ->
  description:string ->
  ?conn:(module Caqti_lwt.CONNECTION) ->
  unit ->
  (Instance.t, Qed_error.t) Result.t Lwt.t

val find_template_by_id :
  string ->
  ?conn:(module Caqti_lwt.CONNECTION) ->
  unit ->
  (Template.t option, Qed_error.t) Result.t Lwt.t
val find_instances_by_character_id : string -> (Instance.t list, Qed_error.t) Result.t Lwt.t
val find_active_instances_by_character_id : string -> (Instance.t list, Qed_error.t) Result.t Lwt.t
val find_active_instances_with_templates : string -> ((Instance.t * Template.t) list, Qed_error.t) Result.t Lwt.t

(* Retrieve the template for a given lore card instance in a single join *)
val find_template_by_instance_id : string -> (Template.t option, Qed_error.t) Result.t Lwt.t
val set_active_status : instance_id:string -> is_active:bool -> (unit, Qed_error.t) Result.t Lwt.t 