# Randomized Gym Challenge

**Randomized Gym Challenge** is an experimental, configurable gym-battle mode for Pokémon Red, Blue, Yellow, and Gold in Gen 1 Recomp. It is not a replacement for the normal game and it is not a ROM hack. It builds a persistent challenge plan for the gyms in a save, while each physical gym keeps its normal badge, reward, and progression event.

This project is **AI-assisted**, not AI-created.

> **WIP alpha:** This mod is installable and activatable for Gen 1 Recomp testing, but it should be used on a test save until cross-generation playthrough testing is complete. Alpha releases are updater-visible; they are not stable releases.

## What it can randomize

Every gameplay option starts **Off**. Enable the combination you want before visiting a gym, then start a new save or use the explicit **REBUILD CHALLENGE (TEST)** action to create a new plan for that save.

| Setting | What it changes |
|---|---|
| Randomize Gym Leaders | A different leader occupies each gym. Their sprite and opening dialogue follow them, while the building keeps its own badge and reward flow. |
| Randomize Team Composition | Generates gym-leader teams from the game’s imported Pokémon roster. The physical gym still determines the team size. |
| Randomize Levels | Varies each slot around that physical gym’s intended level curve. |
| Preserve Gym Type Theme | Uses the physical gym’s type concept. For example, Brock’s gym selects Rock- or Ground-type candidates. |
| Enforce Evolution Stage | Tries to match the base, middle, or final evolution stage of the original team slot. |
| Randomize Movesets | Uses moves the generated species can know at its generated level and prefers at least one damaging move. |
| Randomize Held Items (Gold) | Gives generated Gold gym Pokémon a safe held item or no item. Key items, HMs, non-tossable items, and no-effect held items are excluded. |
| Difficulty Preset | Before a plan exists, applies MANUAL, STORY FRIENDLY, CHALLENGE, or CHAOS defaults to the existing rule set. |
| Progress History | Shows the active phase, completed and next gyms, Crystal status, and claimed Gym Guide rewards. |
| Next Gym Hint | Shows the next physical gym as guidance only; it does not warp or change story state. |

The challenge plan is saved under this mod’s own save data. A configuration change after the plan exists does not silently reroll teams in the middle of a run. Presets only affect plan creation, and the explicit test rebuild action is required when you intentionally want a new plan.

The **OPEN PROGRESS HISTORY** action records completed physical gyms, the next gym in the current phase, Crystal 251 detection status, and one-time Gym Guide reward quantities. **SHOW NEXT GYM HINT** is read-only guidance. Neither action changes badges, warps, rewards, or story flags.

## Gym Challenge mode — new and untested

**Gym Challenge** is an optional progression mode offered once at the end of the native opening sequence. In Red, Blue, and Yellow, it appears only after the player has chosen a starter, beaten the Oak’s Lab rival, and that victory script has completed. In Gold, it appears only after the player has received a starter, returned to Elm’s Lab with the Mystery Egg, and handed that egg to Elm. Choosing **No** leaves normal game flow unchanged.

Choosing **Yes** safely updates the already received native starter, fully heals the party, and immediately routes the player to the first physical gym. It does not replace either game’s native starter or early-story scripts.

The selected starter is level-adjusted against the first physical gym’s highest intended level. A starter with a super-effective matchup starts two levels below that baseline, a neutral starter starts two levels above it, and a starter facing a super-effective gym type starts five levels above it. If both sides have a super-effective type relationship, the defensive-risk result is used.

Each physical gym’s non-battling **Gym Guide** keeps their native dialogue, then offers one weighted encouragement item when spoken to during an active Gym Challenge. Rewards are saved per gym, use a curated no-junk pool, and lean toward stronger recovery or training supplies later in a phase. Some repeatable recovery supplies can award a bounded quantity in later phases. Gold uses its native Gym Guide where one is present; if a gym has no live guide, its leader provides the same one-time parting gift after the native reward and before routing onward.

After each physical gym badge and native reward flow resolves, Gym Challenge heals the party and routes the player to the next gym. Gen 1 runs through the eight Kanto gyms, then leaves the Elite Four and Champion path entirely native. Gold runs through Johto’s eight gyms, preserves the first native Hall of Fame and credits sequence, and continues with the eight Kanto gyms only after the post-credits Continue boot in New Bark Town. It does not force league, Champion, credits, or story transitions. After the final physical gym in a phase, a passive completion message confirms the handoff without forcing the next story event.

> **Do not rely on Gym Challenge for a regular playthrough yet.** This alpha feature passed static and scripted regression checks but has not received a full live playthrough in Red, Blue, Yellow, or Gold.

## Compatibility

The package targets **Red, Blue, Yellow, and Gold** with Mod API 2. It was statically checked with Gen 1 Recomp’s Gen 2 compatibility checker and uses the documented gym-battle seams rather than raw ROM data.

**Crystal 251 is optional.** In Red, Blue, and Yellow, the mod detects Crystal 251 when available and reads its merged live registries for Pokémon, trainers, items, types, and maps. It clones imported records when generating challenge content and does not replace Crystal’s story, battle, evolution, or map systems. Without Crystal 251, standalone behavior is unchanged.

Do **not** enable this at the same time as [Gym Leader Shuffle](https://github.com/inmento/Gym-Leader-Shuffle). Both mods change the gym-leader battle path, so this package declares a direct conflict to prevent an unsafe combination.

## Installing the alpha build

Download the ZIP from the repository’s **Releases** page, extract the `randomized_gym_challenge` folder into the Gen 1 Recomp `mods` folder, then enable it for the game you are testing.

The mod contains no ROM content, extracted game data, or game assets.

## WIP testing focus

Please test a new save and an existing test save separately. Confirm that the opening leader text, overworld sprite, generated party, physical-gym reward, save/reload behavior, and challenge log agree in at least an early, mid-game, and late-game gym. On Gold, also test a Johto gym and a Kanto gym, then repeat with held-item randomization enabled.

For Gym Challenge, verify that no prompt appears during Oak’s introduction. In Gen 1, verify the offer only appears after the Oak’s Lab rival victory completes; in Gold, verify it only appears after Elm receives the Mystery Egg. Test both prompt answers, the three type-adjustment outcomes, the immediate first-gym heal and warp, the first post-reward heal and warp, each Gym Guide’s first-talk reward and repeat talk, bounded reward quantities, a full item bag, save/reload before and after a guide reward, progress history, next-gym hints, all four presets before plan creation, Gen 1 gym-trainer dialogue and statue names, Gold guide-less fallback rewards, Gold’s native first Hall of Fame and credits sequence, and the subsequent Continue boot into the Kanto phase. If Crystal 251 is active, repeat at least one early and one late gym with imported species and trainer data.

If you report an issue, include the game, gym, enabled options, whether the challenge was rebuilt, and a screenshot or log excerpt if possible.
