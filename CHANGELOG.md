# Changelog

## 1.0.3-alpha — Gym Guide Encouragement Rewards

Gym Challenge now gives each physical gym one extra, optional encouragement reward. In Red, Blue, and Yellow, talking to the native non-battling Gym Guide first shows that guide’s normal dialogue, then provides a short challenge-specific warning and one weighted item. The reward is recorded per gym, cannot be claimed twice, never comes from a junk, key-item, HM, or TM pool, and shifts toward stronger recovery or training supplies later in the challenge.

Gold uses the same native Gym Guide flow whenever a live Gym Guide is present. A gym without a live guide uses a leader parting-gift fallback after the native gym reward and before the existing heal-and-warp sequence, so every Gym Challenge stop still has one safe extra reward.

Release ZIP assets now omit `alpha` from their filenames for easier updater testing. The release tags and embedded manifest versions retain their explicit `1.0.x-alpha` identifiers, and the historical alpha release notes and asset names are being normalized the same way.

This remains an **explicitly untested experimental alpha**. Use a separate test save and do not enable it together with Gym Leader Shuffle.
