# Randomized Gym Challenge

**Randomized Gym Challenge** is an experimental, configurable gym-battle mode for Pokémon Red, Blue, Yellow, and Gold in Gen 1 Recomp. It is not a replacement for the normal game and it is not a ROM hack. It builds a persistent challenge plan for the gyms in a save, while each physical gym keeps its normal badge, reward, and progression event.

This project is **AI-assisted**, not AI-created.

> **WIP pre-release:** This mod is marked experimental. It is disabled by default after installation and should be used on a test save until cross-generation playthrough testing is complete.

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

The challenge plan is saved under this mod’s own save data. A configuration change after the plan exists does not silently reroll teams in the middle of a run. Use the test rebuild action when you intentionally want a new plan.

## Compatibility

The package targets **Red, Blue, Yellow, and Gold** with Mod API 2. It was statically checked with Gen 1 Recomp’s Gen 2 compatibility checker and uses the documented gym-battle seams rather than raw ROM data.

Do **not** enable this at the same time as [Gym Leader Shuffle](https://github.com/inmento/Gym-Leader-Shuffle). Both mods change the gym-leader battle path, so this package declares a direct conflict to prevent an unsafe combination.

## Installing the pre-release

Download the ZIP from the repository’s **Releases** page, extract the `randomized_gym_challenge` folder into the Gen 1 Recomp `mods` folder, then enable it for the game you are testing. The experimental confirmation is expected.

The mod contains no ROM content, extracted game data, or game assets.

## WIP testing focus

Please test a new save and an existing test save separately. Confirm that the opening leader text, overworld sprite, generated party, physical-gym reward, save/reload behavior, and challenge log agree in at least an early, mid-game, and late-game gym. On Gold, also test a Johto gym and a Kanto gym, then repeat with held-item randomization enabled.

If you report an issue, include the game, gym, enabled options, whether the challenge was rebuilt, and a screenshot or log excerpt if possible.
