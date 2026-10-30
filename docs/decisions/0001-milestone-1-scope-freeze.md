# 0001: Milestone 1 scope and freeze

- Status: accepted · 30.10.2026 · decided by neVs (interview rounds 2–3, recommendations accepted)
- Context: `docs/scope-first-route.md` (sword, human enemies, no guns for Rend) and GDD §2/§6 no longer match the game. The code (route V12) has the robot arm, four guns, six robot types and a partial farming system. A swarm needs one binding description.

## Decision

1. `docs/milestone-1.md` is the binding specification for M1. `docs/scope-first-route.md` and GDD §2/§6 are historical.
2. M1 content: 6 robot types, 6 weapons + throwable crates, one pressure task, intro comic, English text, four accessibility options (brief S13–S17, G10, G16).
3. Frozen until M1 is accepted: servo trial and prefix ledger (farming; the item catalog is M1 equipment), duelist and brute as standalone robot types (their code stays in M1: shield bearer = duelist + shield, overseer builds on brute), grenades, capture, puzzles, in-game comic inserts. Frozen code stays and its tests must stay green.

## Consequences

- Tasks outside this scope are not created before neVs accepts M1.
- Measurable done criteria (brief G6) replace "neVs accepts" as the only gate; neVs's acceptance stays the last step.
