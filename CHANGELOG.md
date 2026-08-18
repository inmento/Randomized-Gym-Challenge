# Changelog

## 1.1.2 — Release metadata and clean package maintenance

Randomized Gym Challenge now declares its tested **Gen1Recomp API 2** compatibility floor (`>=0.1.99`) in the manifest, allowing the launcher and mod indexes to evaluate the release before installation.

The distributed ZIP has been rebuilt as a clean player package. It retains the mod, manifest, and player documentation while excluding local regression harnesses, testing instructions, internal design notes, research notes, and packaging metadata. No challenge rules, gym generation, Gym Challenge progression, recovery controls, Gold Continue checkpoint, teleport routing, rewards, or Crystal 251 behavior has changed.

The 1.1.2 source and final install archive pass current Gen1Recomp 0.2.3 validation, linting, Gen 2 compatibility checks, and the saved Gen 1 and Gold regression harnesses.
