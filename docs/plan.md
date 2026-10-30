# Plan

> Maintained by the lead. Milestone spec: `docs/milestone-1.md`. Status of each session: `docs/status.md`.

## M1: the first escape route

### Phase F: foundation (lead, level D) — blocks all code tasks

| ID | Work | State | Unblocks |
|---|---|---|---|
| F1 | milestone-1.md, plan, status, ADR 0001 | done 30.10. | everything |
| F2 | triage the 28 quarantined tests: rewrite / repair task / retire (ADR) | next | E1 |
| F3 | split `lab_route.gd`: route data (encounters, props, PA cues, checkpoints) and a text table as extension points | open | E3, E5, E6, E7 |
| F4 | headless test `route_playthrough`: start → airlock (criterion a) and retry < 10 s (c) | open | E2, E9 |
| F5 | `swarvex env` green without network; add `.agents/**` to protected paths | blocked: rootless Podman (needs neVs, sudo) | first code task |
| F6 | `docs/architecture.md` (module map, extension points), style-guide stub | open | B tasks |

### Running now (level A, no code dependency)

| Task | Title | State |
|---|---|---|
| #1–#6 | bestiary pages: guard, shield bearer, sentinel, dog, drone, overseer | open |
| #7, #8 | comic style guide proposal, variants 1/2 and 2/2 | open |
| #9, #10 | intro comic script, variants 1/2 and 2/2 | open |

### Epics after the foundation (sliced once F2–F4 are done)

| Epic | Content | Depends on |
|---|---|---|
| E1 | M1 tests green: one repair task per quarantined test kept by F2 | F2 |
| E2 | timing and route length (S23): playtests, then extend or cut | F4, playtests |
| E3 | pressure task: quick-maths door after the relay checkpoint | F3 |
| E4 | intro comic: pick script + style (neVs) → asset brief preview → final → in-game player | #7–#10 |
| E5 | English in-game text from the text table | F3 |
| E6 | accessibility: subtitles, slow-motion and screen-shake toggles, alarm ≤ 3 Hz | F3 |
| E7 | readable danger: every tell ≥ 0.5 s (from bestiary gaps), boss 60–150 s | #1–#6, E1 |
| E8 | Windows export + smoke test | F5 |
| E9 | performance measurement on the reference PC | F4 |
| E10 | sign-off: playtests neVs + 2 fresh eyes, credits, itch.io slice | all |

Critical path: F2 → F3 → F4 → E1/E3/E7 → E2 → E10.
