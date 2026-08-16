# Gym Challenge implementation research notes

## Official Gen 1 Recomp interfaces

The official Mod API supports the shared `intro.oak_speech.build` hook in both Gen 1 and Gold. It receives the intro steps and can add a `yesno` step with a `saveKey`. `intro.oak_speech.answered` exposes `{ speech, step, index, label, value, saveKey }`; `intro.oak_speech.finished` is emitted immediately before the intro screen pops. Source: `/home/ubuntu/gen1recomp_wiki/Reference-Hooks.md`, `/home/ubuntu/gen1recomp_wiki/Reference-Events.md`, and `/home/ubuntu/gen1recomp_current/src/ui/OakSpeech.lua` plus `src/ui/gen2/OakSpeech.lua`.

The shared post-player-name anchor is `name_player`. Gold’s default Oak Speech sequence uses `ask_player_name`, `name_player`, `legend`, and `shrink` before ending. A Gym Challenge opt-in can therefore be placed immediately after `name_player` in both generations without replacing the naming flow.

`map.entered` is supported and emits `{ mapId, map, fromMapId, via }`. `script.command` wraps dispatched Gen 1 rows and Gold bytecode commands. Gen 1 `open_mart` etc. are unrelated but prove the wrapper shape. `save.new_game` is the supported save skeleton hook.

## Gen 1 starter lab gate

`data/scripts/oaks_lab.lua` shows that Oak Lab starter balls require `EVENT_FOLLOWED_OAK_INTO_LAB` and reject a pick otherwise. Setting that flag before routing to `OAKS_LAB` allows the normal starter-ball selection flow. `EVENT_GOT_STARTER` is set only by the native starter-ball script after the player chooses. The existing starter flow handles ball hiding, rival counter-pick, party creation, and subsequent lab battle logic. The safe rule is to set only the pre-selection gate, not the post-selection completion flag.

## Current Randomized Gym Challenge and reusable Gym Leader Shuffle patterns

Randomized Gym Challenge alpha.2 already has separate Gen 1/Gold gym tables, physical-gym reward preservation, visiting leader sprite projection, Gen 1 leader pre-battle source dialogue projection, Gold intro text projection, and party substitution. It maintains a per-save `challenge_plan` and generates candidate parties by cloning source party records.

Gym Leader Shuffle’s Gen 1 leader-talk pattern retains the physical gym’s defeated-state advice, badge, TM, flags, and reward callback while using the visiting leader only for pre-battle dialogue. Its gym-trainer pattern reads the source trainer header for challenge/victory/repeat text and keeps normal trainer defeat tracking and battle timing. Its statue projection uses the Gen 1 `data.scripts.gyms` table and must not be used in Gold, where equivalent statues are not a hidden event feature.

## Gold shop / special caveat

Gold map-specific leader dialogue uses `seenText`/`winText`/script paths rather than the Gen 1 map header approach. Gold does not have a Gen 1-style `data.scripts.gyms` statue event. Any reused leader/NPC presentation must keep Gold on its existing Gold-specific path.

## Investigation still required

The supplied `/home/ubuntu/golddata/scripts.lua` is a flat script-key table and must be located by actual Elm Lab keys/flags before direct Gold starter-lab routing is added. Do not invent Gold event flags or bypass the native Elm starter script.
