# 0006: Death keeps the shards

- Status: accepted · 14.11.2026 · decided by neVs (message 15, option A)
- Context: `docs/gdd.md` §4 and the glossary described a Hollow-Knight death drop (shards fall at the place of death, recoverable once). Code, tests and `docs/design/farming-design-v02.txt` §8 say the opposite.

## Decision

Rend **keeps his shards and everything collected when he dies**. There is no drop penalty. The old death cache survives only to read old save files. Whether a drop penalty returns is reopened after the playtests.

## Consequences

- GDD §4 and the glossary entry for "shards" are updated to match. Tests (#65) stay as they are.
- `docs/project-brief.md` (S4, S15) still names the "Todes-Cache"; it is protected and is corrected by neVs.
