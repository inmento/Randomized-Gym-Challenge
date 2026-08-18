# Changelog

## 1.1.3 — Merged live-species compatibility

When optional team randomization is enabled, Randomized Gym Challenge now builds eligible species candidates from the **merged live Pokédex range** instead of a fixed Gen 1 ceiling. It only accepts complete registered species records and does not patch foreign species stats, types, learnsets, sprites, or evolution data.

This allows compatible expanded-roster providers, including Crystal 251, to contribute valid species to generated Gym teams when they are active. The native 151-species behavior remains unchanged when no expansion provider is installed. The standalone Gen 1 Shedinja mod remains a separate #152 data provider and should not be combined with Crystal 251.

Gym Leader Shuffle remains intentionally incompatible because both mods alter the same Gym leader, trainer-party, script, NPC, and map state systems.
