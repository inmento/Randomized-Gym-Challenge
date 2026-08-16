# Changelog

## 0.1.0-alpha.2 — WIP Bug-Fix Pre-release

This WIP build fixes the alpha.1 party-construction bug. The generator previously rebuilt every party slot with only `species` and `level`, which could discard vanilla moves, held items, and other imported party fields even when the related randomization options were disabled. Alpha.2 now clones the source party record and changes only fields selected by the active challenge rules. When generated species change, moves and items are refreshed only when the corresponding option is enabled.

Gold’s held-item option now represents no item by omitting the field rather than storing a false value. This remains an experimental pre-release and conflicts with Gym Leader Shuffle because both mods alter the same gym-leader battle paths. Manual gameplay testing is still required before a stable release.
