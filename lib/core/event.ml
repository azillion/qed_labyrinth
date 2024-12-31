(* Core event data that all events will have *)
type base = { id : string; timestamp : float } [@@deriving yojson]

(* Movement-related events *)
module Movement = struct
  type t = {
    base : base;
    from_space_id : Space.id;
    to_space_id : Space.id;
    direction : string;
  }
  [@@deriving yojson]

  let create ~from_space_id ~to_space_id ~direction =
    let timestamp = Unix.gettimeofday () in
    let ctx = Digestif.SHA1.init () in
    let ctx = Digestif.SHA1.feed_string ctx "player_moved" in
    let ctx = Digestif.SHA1.feed_string ctx from_space_id in
    let ctx = Digestif.SHA1.feed_string ctx to_space_id in
    let ctx = Digestif.SHA1.feed_string ctx direction in
    let ctx = Digestif.SHA1.feed_string ctx (string_of_float timestamp) in
    let hash = Digestif.SHA1.get ctx in
    let id = String.sub (Digestif.SHA1.to_hex hash) 0 32 in
    { base = { id; timestamp }; from_space_id; to_space_id; direction }
end

(* Observation-related events *)
module Observation = struct
  type t = { base : base; space_id : Space.id } [@@deriving yojson]

  let create ~space_id =
    let timestamp = Unix.gettimeofday () in
    let ctx = Digestif.SHA1.init () in
    let ctx = Digestif.SHA1.feed_string ctx "player_looked" in
    let ctx = Digestif.SHA1.feed_string ctx space_id in
    let ctx = Digestif.SHA1.feed_string ctx (string_of_float timestamp) in
    let hash = Digestif.SHA1.get ctx in
    let id = String.sub (Digestif.SHA1.to_hex hash) 0 32 in
    { base = { id; timestamp }; space_id }
end

(* Main event type combining all categories *)
type t = PlayerMoved of Movement.t | PlayerLooked of Observation.t
[@@deriving yojson]

let get_id = function PlayerMoved e -> e.base.id | PlayerLooked e -> e.base.id

let get_timestamp = function
  | PlayerMoved e -> e.base.timestamp
  | PlayerLooked e -> e.base.timestamp

(* Constructors for easier event creation *)
let player_moved ~from_space_id ~to_space_id ~direction =
  PlayerMoved (Movement.create ~from_space_id ~to_space_id ~direction)

let player_looked ~space_id = PlayerLooked (Observation.create ~space_id)
