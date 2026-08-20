# Randomized Gym Challenge

**Randomized Gym Challenge** is an experimental, configurable gym-battle mode for Pokémon Red, Blue, Yellow, and Gold in Gen 1 Recomp. It is not a replacement for the normal game and it is not a ROM hack. It builds a persistent challenge plan for the gyms in a save, while each physical gym keeps its normal badge, reward, and progression event.

This project is **AI-assisted**, not AI-created.

> **Testing guidance:** This mod is installable and activatable for Gen 1 Recomp. Use a test save until cross-generation playthrough testing is complete.

## What it can randomize

Every gameplay option starts **Off**. Enable the combination you want before visiting a gym, then start a new save or use the explicit **REBUILD CHALLENGE (TEST)** action to create a new plan for that save.

| Setting | What it changes |
|---|---|
| Randomize Gym Leaders | A different leader occupies each gym. Their sprite and opening dialogue follow them, while the building keeps its own badge and reward flow. |
| Randomize Team Composition | Generates gym-leader teams from the valid merged live Pokémon roster. The physical gym still determines the team size. |
| Randomize Levels | Varies each slot around that physical gym’s intended level curve. |
| Preserve Gym Type Theme | Uses the physical gym’s type concept. For example, Brock’s gym selects Rock- or Ground-type candidates. |
| Enforce Evolution Stage | Tries to match the base, middle, or final evolution stage of the original team slot. |
| Randomize Movesets | Uses moves the generated species can know at its generated level and prefers at least one damaging move. |
| Randomize Held Items (Gold) | Gives generated Gold gym Pokémon a safe held item or no item. Key items, HMs, non-tossable items, and no-effect held items are excluded. |
| Difficulty Preset | Before a plan exists, applies MANUAL, STORY FRIENDLY, CHALLENGE, or CHAOS defaults to the existing rule set. |
| Progress History | Shows the active phase, completed and next gyms, Crystal status, and claimed Gym Guide rewards. |
| Next Gym Hint | Shows the next physical gym as guidance only; it does not warp or change story state. If a route is paused, it also shows the saved reason. |
| Abandon Gym Challenge | Shows a confirmation before clearing only this mod’s active Gym Challenge state and generated plan. Native badges, story flags, party records, and inventory are left intact. |

The challenge plan is saved under this mod’s own save data. A configuration change after the plan exists does not silently reroll teams in the middle of a run. Presets only affect plan creation, and the explicit test rebuild action is required when you intentionally want a new plan.

The **OPEN PROGRESS HISTORY** action records completed physical gyms, the next gym in the current phase, Crystal 251 detection status, one-time Gym Guide reward quantities, and the last route status, target, and diagnostic reason. **SHOW NEXT GYM HINT** is read-only guidance and repeats any paused-route reason. Neither action changes badges, warps, rewards, or story flags.

## Gym Challenge mode — new and untested

**Gym Challenge** is an optional progression mode offered once at the end of the native opening sequence. In Red, Blue, and Yellow, it appears only after the player has chosen a starter, beaten the Oak’s Lab rival, returned Oak’s Parcel, received the Pokédex, and the full Oak’s Lab cutscene has finished. In Gold, it appears only after the player has received a starter, returned to Elm’s Lab with the Mystery Egg, and handed that egg to Elm. Choosing **No** leaves normal game flow unchanged.

Choosing **Yes** first shows a concise start summary listing the first gym, saved difficulty preset, and enabled rules. It then safely updates the already received native starter, restores party HP without refilling move PP, and routes the player to the first physical gym. It does not replace either game’s native starter or early-story scripts.

The selected starter is level-adjusted against the first physical gym’s highest intended level. A starter with a super-effective matchup starts two levels below that baseline, a neutral starter starts two levels above it, and a starter facing a super-effective gym type starts five levels above it. If both sides have a super-effective type relationship, the defensive-risk result is used.

Each physical gym’s non-battling **Gym Guide** keeps their native dialogue, then offers one weighted encouragement item when spoken to during an active Gym Challenge. Rewards are saved per gym, use a curated no-junk pool, and lean toward stronger recovery or training supplies later in a phase. Some repeatable recovery supplies can award a bounded quantity in later phases. In Gen 1, once that physical gym is complete and a player has deferred its next route, the same Gym Guide instead offers to continue the queued challenge route. Gold uses its native Gym Guide where one is present; if a gym has no live guide, its leader provides the same one-time parting gift after the native reward and before routing onward.

After each physical gym badge and native reward flow resolves, Gen 1 asks whether the player wants to continue immediately. Choosing **Yes** restores party HP only—never move PP—and routes to the queued destination. Choosing **No** keeps that destination queued; the player may prepare normally, then speak to the completed gym’s Gym Guide to receive the same choice. A failed or invalid warp leaves the player in place, preserves the pending destination, and records a paused status for Progress History rather than forcing the next story event. After the eighth Gen 1 badge, the final choice sends the player to the south end of Route 23 before every native badge guard and Victory Road, leaving the rival, cave, Elite Four, and Champion route native. Gold has two explicit physical-gym phases: Johto gyms 1–8, followed by the native first Elite Four, Champion, Hall of Fame, and credits; then, on the next Continue boot in New Bark Town, the player is asked whether to continue. **Yes** reactivates routing and sends the player to Kanto gym 9, while **No** leaves the native post-game route untouched. After Kanto gyms 9–16, routing stops again and the player proceeds naturally through the second Elite Four and Champion. The second Champion victory completes the challenge and disables challenge teleports for that save. The mod does not force either league, Champion, credits, or story transition.

> **Use a separate save for first-time Gym Challenge testing.** The feature passed static and scripted regression checks but has not received a full live playthrough in Red, Blue, Yellow, or Gold.

## Compatibility

The package targets **Red, Blue, Yellow, and Gold** with Mod API 2. It was statically checked with Gen 1 Recomp’s Gen 2 compatibility checker and uses the documented gym-battle seams rather than raw ROM data.

**Expanded Pokédex providers are optional.** In Red, Blue, and Yellow, the mod reads the effective merged dex range and only selects complete live species records when generating optional teams. Crystal 251 is a supported provider: its Pokémon, trainers, items, types, and maps are read without replacing Crystal’s story, battle, evolution, or map systems. Other compatible providers can contribute valid records under the same rule. Without an expansion provider, standalone native-roster behavior is unchanged.

Do **not** enable this at the same time as [Gym Leader Shuffle](https://github.com/inmento/Gym-Leader-Shuffle). Both mods change the gym-leader battle path, so this package declares a direct conflict to prevent an unsafe combination.

## Installing the current version

Download the ZIP from the repository’s **Releases** page, extract the `randomized_gym_challenge` folder into the Gen 1 Recomp `mods` folder, then enable it for the game you are testing.

The mod contains no ROM content, extracted game data, or game assets.

## WIP testing focus

Please test a new save and an existing test save separately. For an existing Gen 1 save that has already defeated the Oak’s Lab rival, delivered Oak’s Parcel, and received the Pokédex but has not accepted or declined Gym Challenge, return to Oak’s Lab to receive the one-time offer; no replay of the rival battle or new save is required. Confirm that the opening leader text, overworld sprite, generated party, physical-gym reward, save/reload behavior, and challenge log agree in at least an early, mid-game, and late-game gym. On Gold, also test a Johto gym and a Kanto gym, then repeat with held-item randomization enabled.

For Gym Challenge, verify that no prompt appears during Oak’s introduction. In Gen 1, verify the offer appears only after the completed Oak’s Parcel/Pokédex cutscene and the rival’s departure, and confirm ordinary gym trainers still auto-engage on sight. Test both prompt answers, the start summary, the three type-adjustment outcomes, the first-gym HP-only warp, each post-reward continuation answer, the deferred Gym Guide continuation after a Pokémon Center visit, preservation of move PP, the eighth-badge Route 23 handoff before all badge guards, each Gym Guide’s first-talk reward and repeat talk, bounded reward quantities, a full item bag, save/reload before and after a guide reward, Progress History route status, paused-route diagnostics, the confirmation-gated abandon action, all four presets before plan creation, Gen 1 gym-trainer dialogue and statue names, Gold guide-less fallback rewards, Gold’s first eight gyms followed by the native first Elite Four, Champion, Hall of Fame, and credits, the Continue prompt on the next New Bark boot, both Continue answers, Kanto gyms 9–16, the second native Elite Four and Champion, and final challenge completion. If Crystal 251 is active, repeat at least one early and one late gym with imported species and trainer data.

If you report an issue, include the game, gym, enabled options, whether the challenge was rebuilt, and a screenshot or log excerpt if possible.
