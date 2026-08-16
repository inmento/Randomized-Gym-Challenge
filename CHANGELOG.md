# Changelog

## 1.0.4-alpha — Crystal-Safe Challenge Controls and Progress History

Added optional **Crystal 251** detection for Red, Blue, and Yellow. When Crystal 251 is active, Randomized Gym Challenge reads the merged live Pokémon, trainer, item, type, and map registries without replacing Crystal-owned story, battle, evolution, or map data. The mod remains standalone and does not require Crystal 251.

Added read-only **OPEN PROGRESS HISTORY** and **SHOW NEXT GYM HINT** actions. Progress history reports the active phase, completed and next physical gyms, Crystal status, and each Gym Guide reward already claimed. Hints identify the next physical gym without forcing a warp or changing native story progression.

Added pre-plan difficulty presets: **MANUAL**, **STORY FRIENDLY**, **CHALLENGE**, and **CHAOS**. Presets configure the existing challenge rules only while a plan is being created. Once a save has a challenge plan, changing settings does not silently reroll its teams; the explicit rebuild action remains required.

Gym Guide encouragement rewards now persist their quantity as well as their item. Curated repeatable supplies can award a bounded quantity later in a challenge phase, while rare rewards remain single-item gifts. Bag-full behavior still leaves the reward unclaimed so it can be retried safely.

After the final physical gym in a phase, the mod can show a passive completion acknowledgment and then leaves the native league and story path in control. It does not force the Elite Four, Champion, Hall of Fame, credits, or Gold’s post-credits Kanto handoff.

Gen 1 and Gold regression harnesses, official validation, linting, Gen 2 safety checking, reproducible packaging, and archive integrity checks pass. This remains an **explicitly untested experimental alpha** and requires live testing on separate saves, especially with Crystal 251 active.
