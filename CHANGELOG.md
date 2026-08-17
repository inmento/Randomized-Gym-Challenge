# Changelog

## 1.1.0 — Gym Challenge Release Hardening

Added **ABANDON GYM CHALLENGE**, a confirmation-gated per-save recovery action. Confirming it clears only this mod’s active Gym Challenge state and generated plan; native badges, story flags, party records, and inventory remain untouched.

Gym Challenge routing now records its queued, completed, or paused state. Before a warp, the mod verifies that a valid destination exists. A failed or invalid warp preserves the pending next gym and pauses safely instead of forcing progression. **OPEN PROGRESS HISTORY** and **SHOW NEXT GYM HINT** now expose the route target and a readable status reason.

Accepting Gym Challenge now shows a start summary before the first heal and warp. The summary identifies the first gym, persisted difficulty preset, and enabled challenge rules so a tester can reproduce the run.

The Gen 1 and Gold regression harnesses now cover first-gym route status, safe failed-warp handling, confirmation-gated abandonment, and native-record preservation. Do not enable this together with Gym Leader Shuffle.
