# Gym Challenge mode design

## Scope and state

Gym Challenge is an opt-in WIP mode within Randomized Gym Challenge. It is independent of the existing configurable battle-generation toggles, which remain all-Off by default. A per-save `gym_challenge_state` will hold at least the selected state, current phase, completed physical gyms, initial badge count, starter-ready marker, starter-level marker, and a queued destination. No global game flags are used for mod-owned state.

The prompt is injected after the shared `name_player` Oak Speech step with the supported `intro.oak_speech.build` hook. It uses a `yesno` row and a private `saveKey`. `intro.oak_speech.answered` records the choice; `intro.oak_speech.finished` schedules the mode only when the player answered Yes. A No answer leaves vanilla play untouched.

## Native starter flow

The mode does not create a substitute starter script. It routes to the native starter lab after the intro completes and lets native ball/gift scripts handle selection, rival state, object hiding, and story data.

| Generation | Route | Native pre-selection state |
|---|---|---|
| Gen 1 | `OAKS_LAB`, safe entrance-side coordinate | Set only `EVENT_FOLLOWED_OAK_INTO_LAB`; the native ball scripts require this flag and write `EVENT_GOT_STARTER` themselves after the player chooses. |
| Gold | `ELMS_LAB`, entrance-side coordinate | Do not invent or set numeric Gold event flags. Native starter-ball scripts accept an unset starter-completion event and write their own state after selection. |

The player starter level is adjusted only once, at the native Lab gift seam. Gen 1 uses the mutable `pokemon.before_give` event and guards the Oak Lab context. Gold uses the supported `script.command` wrapper on Elm’s three real starter `givepoke` script keys. No rival gift, unrelated story gift, or existing save starter is changed.

## Starter level rule

The first physical gym’s highest vanilla party level is the baseline. Compare the chosen starter’s two types against the first physical gym’s theme types through `mod.content.type_chart` rows keyed as `ATTACKER>DEFENDER`; multiplier `>= 20` is super-effective.

| Relationship | Starter level |
|---|---:|
| Starter is super-effective against the first gym | baseline − 2, minimum 2 |
| First gym is super-effective against the starter | baseline + 5 |
| Neither side has a super-effective matchup | baseline + 2 |

If a dual-type matchup has both an attacking and defending super-effective relationship, the defensive-risk result takes precedence (+5), preventing a starter from receiving a lower level despite a material type disadvantage.

## Gym progression and healing

A completed challenge gym is identified by a post-reward increase in the physical badge state, not merely a trainer victory. Gen 1 observes the physical badge item in `save.inventory`. Gold observes the authoritative `save.player.badges` and `save.player.kantoBadges` stores. The next destination is scheduled only after the relevant script ends with `completed=true`, so the badge and native TM handoff have resolved first. The native `Commands.heal_party` implementation is used immediately before any queued gym warp.

Gym visits use the physical-gym sequence in `GYMS`, skipping already completed challenge destinations. The existing map/leader party plan remains responsible for all leader presentation and battle generation.

## League progression

| Generation | Challenge route |
|---|---|
| Gen 1 | Eight physical gyms, then no mod-driven warp; vanilla Elite Four / Champion progression continues. |
| Gold | Eight Johto gyms, then no mod-driven warp for the first Elite Four / Champion route. When the game’s badge state later reaches the post-first-league Kanto phase, Gym Challenge resumes its queued progression through the eight Kanto gyms. The final Elite Four / Champion route remains vanilla. |

The Gold implementation does not force an Elite Four, Champion, or story transition. It only resumes after the native game visibly reaches the Kanto-badge phase, avoiding invented story flags and allowing normal save progression.

## Leader-following presentation

The existing Gen 1 leader talk projector will preserve the physical gym’s defeated-state advice, badge, TM, flags, and reward flow while using the planned visiting leader for challenge text and battle presentation. Gen 1 gym trainer discovery will be adapted from Gym Leader Shuffle so ordinary battleable NPCs can draw from the visiting gym’s roster, source trainer header dialogue, sprite, and scaled/generated challenge party. Gen 1 statue labels will project the visiting leader name through `data.scripts.gyms`; Gold is intentionally excluded because it does not use that Gen 1 statue interaction.

Gold retains its existing script-key leader intro projection and NPC `seenText`/`winText`-style engine path. Gold NPC roster enhancement must use map objects and trainer script fields only after a verified supported source mapping is available; it will not use the Gen 1 map-header method.

## Live-testing warning

This feature requires live manual testing. Especially verify new-game Yes/No behavior, both native starter labs, first-gym starter levels, post-TM warp timing, bag-full TM retry behavior, all Gen 1 gym trainer dialogue, Gold’s Johto-to-Kanto handoff, and no impact after choosing No.
