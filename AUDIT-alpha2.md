# Static Audit — 0.1.0-alpha.2

## Confirmed defect fixed

Alpha.1 rebuilt every generated party slot as only `{ species, level }`. When all randomization toggles were off, that discarded imported vanilla moves, held items, and any other party fields. Alpha.2 clones the source party record first, changes the selected fields only, clears moves/items only when the species changes, and represents Gold no-item results by omitting the item field.

## Checks completed

- Lua parser: passed.
- Mod manifest validation: passed.
- Repository linter: passed; no ROM-derived content detected.
- Gen 2 compatibility checker: passed; the package loads on Gen 2 under the static checker.
- Official packer: passed; ZIP contents are valid and contain the repository’s current WIP source, documentation, and Gold regression harness plus pack metadata.
- Gold gym identifiers: compared with the verified stable Gym Leader Shuffle Gold table; the WIP uses the same map IDs, object indices, class/member values, script keys, sprites, and intro text keys.
- Gold regression harness: passed. It verifies a 16-gym Gold plan, alpha.2 party-field preservation with all rules disabled, and deep-copy isolation between repeated battle projections.
- Index entry: validated with four total entries and zero warnings; the feed records alpha.2 and its pre-release ZIP.

## Still not statically provable

The sandbox cannot prove live in-game save serialization, exact battle timing on every Recomp build, rendered text-box pagination, physical reward completion after a shuffled Gold leader, or the behavior of every generated moveset/item against a real save. Those remain the focused manual tests for alpha.2.
