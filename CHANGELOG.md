# Changelog

## 1.0.6 — Corrected Challenge Start and First-Gym Routing

Gym Challenge is no longer offered during Oak’s introduction.

In Red, Blue, and Yellow, the offer now appears only after the player has chosen a starter, defeated the native Oak’s Lab rival, and that victory script has completed. In Gold, the offer now appears only after the player has received a starter, returned to Elm’s Lab with the Mystery Egg, and handed the egg to Elm.

Accepting the offer safely updates the already received starter to the challenge’s first-gym level, recalculates its experience and stats, heals the party, and immediately teleports the player to the first physical gym. This replaces the incorrect pre-starter lab routing and eliminates the missing initial gym warp.

The milestone offer is one-time only and no longer intercepts unrelated completed scripts after it has been handled. Incomplete challenge states created by the retired intro flow are cleared safely on load; existing progress with completed gyms is retained.

Version labels, release tags, archive names, and the updater feed now use the same stable `1.0.6` identifier. Gen 1 and Gold milestone, routing, reward, and regression harnesses pass, along with official validation, linting, and Gen 2 safety checks. Use a separate save for first-time Gym Challenge testing, and do not enable it together with Gym Leader Shuffle.
