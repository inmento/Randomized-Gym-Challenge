# Changelog

## 0.1.0-alpha.2 — WIP bug-fix pre-release

This build fixes a confirmed party-construction issue in alpha.1. The generator was rebuilding each party slot with only `species` and `level`, which could discard vanilla moves, held items, and other imported party fields even when the corresponding randomization options were Off. Alpha.2 now clones the source party record first and changes only the fields selected by the player. Generated species also receive fresh moves/items only when those options are enabled.

The Gold held-item option now represents no item with an omitted field rather than a false value, and the package was rechecked with Lua syntax validation, the Gen 2 compatibility checker, the repository linter, and the official packer.

## 0.1.0-alpha.1 — WIP pre-release

This first public test build introduces **Randomized Gym Challenge** for Red, Blue, Yellow, and Gold.

It adds an all-off configuration set for gym-leader assignment, team composition, level variation, physical-gym type themes, evolution-stage matching, legal level-based movesets, and Gold held items. Each save receives a persistent challenge plan, so a generated team cannot change unexpectedly after a save/load. The rebuild action is included specifically for testers who want to generate a fresh plan without making another save.

The build keeps the physical gym’s normal badge, reward, and progression logic. When leader randomization is enabled, the visiting leader supplies the battle presentation while the building still owns its completion flow. Gold item generation filters out key items, HMs, non-tossable items, and no-effect held items.

This version is intentionally experimental and conflicts with Gym Leader Shuffle because both mods alter the same gym-leader battle paths. It passed Lua syntax validation and the engine’s static Gen 2 compatibility check; it still requires manual gameplay testing before any stable release.
