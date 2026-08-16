# Changelog

## 1.0.5-alpha — Installability Metadata Correction

Removed the manifest-level `experimental` marker that prevented Randomized Gym Challenge from being enabled after ZIP import and caused compatible index clients to treat the mod as non-installable. The release remains a **WIP alpha** by version label and documentation, but it is now installable and activatable for live testing.

Bumped the embedded version to `1.0.5-alpha` so updater clients can distinguish this corrected package from the blocked `1.0.4-alpha` build. The release ZIP continues to omit `alpha` from its filename for updater compatibility.

No gym-generation, Gym Challenge, Crystal 251, save-state, or story-flow behavior changed in this hotfix. The prior optional Crystal 251 compatibility, progress history, hints, presets, reward quantities, and passive completion notice remain intact.

Gen 1 and Gold regression harnesses, official validation, linting, Gen 2 safety checking, reproducible packaging, and archive integrity checks pass. Live testing on a separate save is still required, especially with Crystal 251 active. Do not enable this together with Gym Leader Shuffle.
