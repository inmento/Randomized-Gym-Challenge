# Changelog

## 1.1.7 — Gen 1 post-parcel offer correction

This release fixes the Gen 1 Gym Challenge offer failing to appear after the player returns Oak’s Parcel. The offer is now keyed to the completed native Oak’s Lab milestone: the player must have defeated the starter rival, delivered the parcel, and received the Pokédex. This is the exact sequence that finishes after the rival departs.

The existing-save fallback now listens to the engine’s real `map.entered` event instead of the non-emitted `world.map_entered` name. Therefore, a player who has already completed the parcel/Pokédex sequence can simply return to Oak’s Lab and receive the one-time offer; no restart or replay is required.

## 1.1.6 — Existing-save Oak’s Lab offer migration

A save that had already completed the Oak’s Lab starter rival before installing the progression repair could not replay that native exit script. In Gen 1, returning to Oak’s Lab now checks the durable native rival-completion flag and presents the same one-time Gym Challenge offer. Existing saves do not need to restart or replay the rival battle.

## 1.1.5 — Gen 1 Gym Challenge progression repair

This hotfix corrects the Gen 1 post-intro trigger by recognizing the Oak's Lab starter rival through the engine’s live trainer class. Oak now offers Gym Challenge only after the rival’s complete post-battle departure script has finished.

Gym support trainers no longer receive map talk-script overrides, which had made the engine classify them as script-owned NPCs and skip their normal sight-line approach. They now engage when they see the player again, while their selected source-gym battle, victory, and after-battle dialogue remains projected through the native trainer-header path.

After each earned Gen 1 badge and its native reward, the player is asked whether to continue immediately. Choosing Yes restores party HP only—never move PP—and routes to the queued destination. Choosing No preserves the route; after visiting a Pokémon Center or otherwise preparing, speaking to the physical Gym Guide offers the same continuation. After the eighth badge, the final choice routes to Route 23 before all eight native badge guards and Victory Road, leaving the rival, cave, Elite Four, and Champion progression native.

## 1.1.4 — Compact option labels

All Gen 1 and Gold challenge settings now use labels that fit the fixed 17-column mod-settings viewport. This is a display-only correction: Gym Challenge routing, progress recovery, randomized teams, difficulty presets, held-item rules, hints, rewards, and conflict behavior are unchanged.

## 1.1.3 — Merged live-species compatibility

When optional team randomization is enabled, Randomized Gym Challenge now builds eligible species candidates from the **merged live Pokédex range** instead of a fixed Gen 1 ceiling. It only accepts complete registered species records and does not patch foreign species stats, types, learnsets, sprites, or evolution data.

This allows compatible expanded-roster providers, including Crystal 251, to contribute valid species to generated Gym teams when they are active. The native 151-species behavior remains unchanged when no expansion provider is installed. The standalone Gen 1 Shedinja mod remains a separate #152 data provider and should not be combined with Crystal 251.

Gym Leader Shuffle remains intentionally incompatible because both mods alter the same Gym leader, trainer-party, script, NPC, and map state systems.
