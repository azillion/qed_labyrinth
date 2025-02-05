open Lwt.Infix
open Llm
open Types

(* Initialize clients for all providers *)
module DeepseekClient = Client.Make(Deepseek.Deepseek)(Provider_limits.DeepseekLimits)
module OpenAIClient = Client.Make(Openai.Openai)(Provider_limits.OpenAILimits)
module ClaudeClient = Client.Make(Anthropic.Anthropic)(Provider_limits.ClaudeLimits)

let area_generation_prompt = {|You are generating areas for a dark fantasy MUD (Multi-User Dungeon) where civilization struggles against a hostile, twisted wilderness. Your goal is to create coherent, atmospheric areas that extend logically from the surrounding context while maintaining an unsettling, foreboding tone.

Area Types Available:
- Cave: Underground areas with potential dark secrets
- Forest: Twisted woodlands with ancient mysteries
- Mountain: Forbidding peaks and treacherous climbs
- Swamp: Fetid wetlands harboring ancient evils
- Desert: Harsh wastelands hiding lost ruins
- Tundra: Frozen wastes preserving ancient horrors
- Lake: Dark waters concealing unknowable depths
- Canyon: Deep ravines echoing with strange sounds
- Volcano: Burning lands touched by primal forces
- Jungle: Suffocating growth hiding predatory life

Elevation Guidelines:
- Areas typically stay at ground level (z=0)
- Create areas above (z>0) only for significant high terrain (mountains, cliffs)
- Create areas below (z<0) only for caves, ravines, or underground features
- Vertical transitions must be explicitly justified by terrain

<areaContext>
To the west (1,0,0):
The Whispering Thorn Grove
Ancient blackthorn trees form a dense thicket here, their branches twisted into unnatural angles that seem to reach like grasping fingers. The ground is carpeted with fallen petals that appear white in shadow but reveal hints of dried blood when caught by stray beams of light. A constant, barely audible whisper seems to emanate from the thorny canopy above, though no wind stirs the branches. Between the thorns, half-hidden paths wind deeper into darkness.
Elevation: 0.1
Temperature: 0.1
Moisture: 0.4

To the west of west (0,0,0):
The Ancient Oak Meadow
An ancient oak dominates the hillside, its twisted trunk rising from the earth in massive coils. The tree's vast canopy spreads across the sky, its leaves catching rays of sunlight that pierce through gathering storm clouds above. The meadow blooms with blue cornflowers and crimson poppies dotting the emerald grass.
Elevation: 0
Temperature: 0.2
Moisture: 0.3
</areaContext>

Generate a new area at (2,0,0) that connects logically with these existing areas. Present in this format:

<generatedArea>
<areaName>[Evocative, slightly unsettling name]</areaName>

<description>[3-5 sentences describing the area's foreboding atmosphere and notable features]</description>

<roomType>[One of the specified area types]</roomType>

<elevation>[Value between -1.0 and 1.0, changing ±0.1 max from context]</elevation>

<temperature>[Value between -1.0 and 1.0, changing ±0.1 max from context]</temperature>

<moisture>[Value between -1.0 and 1.0, changing ±0.1 max from context]</moisture>

<z>[Integer indicating vertical level: -1, 0, or 1 only when justified by terrain]</z>

<connections>[Available directions: north, south, east, west, up, down - only include up/down when justified by terrain]</connections>
</generatedArea>|}

let get_env_var name =
  try Sys.getenv name
  with Not_found ->
    Printf.printf "Error: Environment variable %s is not set.\n" name;
    Printf.printf "Please set the following environment variables before running:\n";
    Printf.printf "  DEEPSEEK_API_KEY\n";
    Printf.printf "  OPENAI_API_KEY\n";
    Printf.printf "  ANTHROPIC_API_KEY\n";
    exit 1

let run_provider name client messages =
  let%lwt result = client ~messages () in
  match result with
  | Ok response ->
      Lwt_io.printf "\n=== %s Response ===\n%s\n" name response.text >>= fun () ->
      (match response.usage with
       | Some usage -> Lwt_io.printf "Tokens used: %d\n" usage.total_tokens
       | None -> Lwt.return_unit)
  | Error e ->
      Lwt_io.printf "Error from %s: %s\n" name (string_of_error e)

let run_example () =
  (* Common message list for all providers *)
  let messages = [
    { role = System; 
      content = "You are a world builder for a dark fantasy MUD (Multi-User Dungeon).";
      name = None;
      tool_calls = None };
    { role = User;
      content = area_generation_prompt;
      name = None;
      tool_calls = None };
  ] in

  (* Configure all providers *)
  let deepseek_config = Deepseek.Deepseek.create_config
    ~api_key:(get_env_var "DEEPSEEK_API_KEY")
    ~model:"deepseek-reasoner"
    ~base_url:"https://api.deepseek.com/v1"
    ()
  in
  
  let openai_config = Openai.Openai.create_config
    ~api_key:(get_env_var "OPENAI_API_KEY")
    ~model:"gpt-3.5-turbo"
    ()
  in

  let anthropic_config = Anthropic.Anthropic.create_config
    ~api_key:(get_env_var "ANTHROPIC_API_KEY")
    ()
  in

  (* Create clients *)
  let deepseek = DeepseekClient.create deepseek_config in
  let openai = OpenAIClient.create openai_config in
  let claude = ClaudeClient.create anthropic_config in

  (* Run all providers in parallel *)
  Lwt.join [
    run_provider "Deepseek" (DeepseekClient.complete deepseek) messages;
    run_provider "OpenAI" (OpenAIClient.complete openai) messages;
    run_provider "Claude" (ClaudeClient.complete claude) messages;
  ]

let () = 
  Lwt_main.run (run_example ())