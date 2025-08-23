(**
  NPC Model.
  Manages master records for Non-Player Characters in the `npcs` table.
*)

open Base

type t = {
  id: string; (* This is also the entity_id *)
  archetype_id: string;
  name: string;
  description: string;
}

(**
  Create a new NPC master record.
  This also creates the corresponding master entity record.
  @param archetype_id The ID of the archetype blueprint.
  @param name The unique name for this NPC instance.
  @param description A short description of the NPC.
  @return The newly created NPC record.
*)
val create :
  archetype_id:string ->
  name:string ->
  description:string ->
  (t, Qed_error.t) Result.t Lwt.t


