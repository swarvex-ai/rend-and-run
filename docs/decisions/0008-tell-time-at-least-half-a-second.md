# 0008: Every robot attack warns at least 0.5 s ahead

- Status: accepted · 14.11.2026 · decided by neVs (message 20)

## Decision

Every M1 robot attack gives at least 0.5 s between the first visible tell and the first possible hit. The shared role-1 windup (duelist/shield bearer, sentinel) rises from 0.40 s to 0.43 s (`enemy.gd`, `_windup_duration`). Re-measured with `tell_duration_probe`: the four attacks that measured 0.483 s now measure 0.500 s; all 18 attacks are at 0.500 s or above (`docs/measurements/tell-durations.md`).

## Consequences

- The shield bearer is 30 ms slower and stays the fastest enemy.
- The audible side of the tell is a separate task (decision 0007).
