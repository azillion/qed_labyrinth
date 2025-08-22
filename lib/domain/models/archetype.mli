(**
  NPC Archetype Model.
  An archetype is a blueprint for an NPC, defining its potential behaviors,
  initial state, and AI prompts.
*)

open Base

type t = {
  id: string;
  version: int;
  params: Yojson.Safe.t;
  prompts: Yojson.Safe.t;
}

(**
  Find an archetype by its unique identifier.
  @param id The ID of the archetype (e.g., "archetype_humanoid_artisan").
  @return The archetype record, or None if not found.
*)
val find_by_id : string -> (t option, Qed_error.t) Result.t Lwt.t