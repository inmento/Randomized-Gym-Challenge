# Randomized Gym Challenge — WIP test checklist

Use a separate test save. The mod is experimental and deliberately generates a persistent plan per save.

## Setup and plan behavior

| Check | Expected result |
|---|---|
| Enable the mod with no gameplay toggles enabled. | The game boots, and gym behavior remains functionally vanilla. |
| Enable one or more gameplay toggles before a gym visit. | The first gym access creates one saved challenge plan. |
| Change a gameplay option after visiting a gym. | Existing teams do not silently change; the log reports that a test rebuild is required. |
| Use **REBUILD CHALLENGE (TEST)**. | The action resets to Off and the next gym access builds a new plan. |
| Save, quit, and continue. | Leader assignment and generated teams match the previous plan. |
| Use **OPEN CHALLENGE LOG**. | The action resets to Off and the pages show the same leaders/teams that battles use. |

## Red, Blue, and Yellow

Test Pewter, one middle gym, and Viridian Gym. With leader randomization enabled, confirm that the visiting leader’s opening text and overworld sprite match while the physical building gives its usual badge and TM/reward. Test each option individually, then test the combined configuration below.

| Combined configuration | Expected result |
|---|---|
| Team composition + level variation | Same team count as the physical gym; levels remain near the original curve. |
| Team composition + type theme | Pokémon match the gym’s physical type theme; Brock may use Rock or Ground. |
| Team composition + evolution stage | Team slots follow the original slot’s broad evolution stage where candidates exist. |
| Team composition + movesets | Every generated Pokémon has usable moves and at least one damaging move when a legal candidate exists. |
| All options except Gold items | Leader, team, levels, type/stage limits, and moves all agree with the challenge log. |

Confirm that Giovanni’s Rocket Hideout and Silph Co. appearances remain untouched.

## Gold

Test at least Violet Gym, one middle Johto gym, Blackthorn Gym, Pewter Gym, and Viridian Gym. Confirm that the physical gym keeps its own reward/progression while its generated team and—when enabled—leader presentation match the saved plan.

Repeat one Johto and one Kanto gym with **RANDOMIZE HELD ITEMS (GOLD)** enabled. Generated items must be ordinary held items or no item; no key item, HM, non-tossable item, or no-effect held item should appear.

## Regression and conflict checks

Confirm that disabling the WIP restores normal gym behavior on a copy of the save. Confirm that the mod manager refuses the WIP if Gym Leader Shuffle is enabled at the same time. If any test fails, record the game, gym, active settings, whether a rebuild was used, and whether the issue happened before or after save/load.
