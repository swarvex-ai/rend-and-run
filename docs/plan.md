# Plan

> Maintained by the lead. Milestone spec: `docs/milestone-1.md`. Status of each session: `docs/status.md`.

## M1: the first escape route

### Phase F: foundation (lead, level D) — blocks all code tasks

| ID | Work | State | Unblocks |
|---|---|---|---|
| F1 | milestone-1.md, plan, status, ADR 0001 | done 30.10. | everything |
| F2 | triage the 28 quarantined tests (`docs/test-triage.md`); dash_visual_test promoted to headless | done 30.10. | E1 |
| F3 | split `lab_route.gd`: route data (encounters, props, PA cues, checkpoints) and a text table as extension points | open | E3, E5, E6, E7 |
| F4 | headless test `route_playthrough`: start → airlock (criterion a) and retry < 10 s (c) | open | E2, E9 |
| F5 | `swarvex env` green without network (77/77, 3 min); `.agents/**` protected; runner: `--headless` for named/quarantined tests, named runs fail on red | done 30.10. | first code task |
| F6 | `docs/architecture.md` (module map, extension points), style-guide stub | open | B tasks |

### Running now (level A, no code dependency)

| Task | Title | State |
|---|---|---|
| #1, #3–#6, #43 | bestiary pages: guard, sentinel, dog, drone, overseer; shield bearer #43 (replaces #2) | open |
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
| E11 | menus and baseline package (brief „Grundpaket“, S24): see below | F3 (texts), E11.2 |

Critical path: F2 → F3 → F4 → E1/E3/E7 → E2 → E10.

### E11: menus and baseline package

Reference first, then copies. Existing items are mapped, not duplicated: G-5 → E6, G-14 → F3/E5, B5 → E8, G-7 corrupt save → diagnosis #22, G-8/G-9 → E10 playtests, G-10 retry → F4.

| ID | Work | Level | Depends on |
|---|---|---|---|
| E11.1 | menu style guide, variants 1/2 and 2/2 (`design.ui`, text + mockup description); neVs picks one — tasks #38, #39 | A | – |
| E11.2 | reference menu screen „Options“ (lead, extension point): `MenuScreen` base with transitions, focus animation, UI sounds, back handling; settings store (`user://settings.cfg`, separate from progress); audio buses Music/Voice; contract test | D | E11.1 pick, F3 text table |
| E11.3 | options content: audio sliders, window mode, VSync, accessibility toggles (G16) on the reference screen | B | E11.2, E6 |
| E11.4 | main menu on `MenuScreen`: add Options, Credits, version label | B | E11.2 |
| E11.5 | pause menu on `MenuScreen`: add Options, „Main menu“ | B | E11.2 |
| E11.6 | credits screen from `CREDITS.md` data; reachable from main menu and after the end card | B | E11.2 |
| E11.7 | focus loss pauses the game; window mode switches without restart | B | E11.2 |
| E11.8 | input hints follow the last used device; gamepad hot-plug | B | E11.2 |
| E11.9 | loading indicator at start and reload, no freeze > 1 s | B | E11.2 |
| E11.10 | CHANGELOG.md (SemVer, entry `0.1.0-prealpha`) — task #40 | A | – |
| E11.11 | ~~SECURITY.md~~ — #41 closed: covered by the organization default in swarvex-ai/.github | – | – |
| E11.12 | ~~bug issue form~~ — #42 closed: moved to v1 (backlog); generic form from swarvex-ai/.github until then | – | – |
| E11.13 | app icon + title wordmark (asset brief, preview → neVs → final) | A | style guide |
| E11.14 | itch.io page text + 3–5 screenshots; README player section | A | E10 |

## Roles and gates (LEAD.md 1.5, section 9a)

The lead plays all roles (virtual officers); cards: `lead/roles/game/*.md` in swarvex-ai/swarvex. Every new task names its `role`. Checked 31.10.2026.

| Role | Gate document | State | Open tasks (role) | Gate |
|---|---|---|---|---|
| game-design | `docs/milestone-1.md` (M1 rules, route), `docs/gdd.md` (historical core loop) | exists; level briefs and balance-as-data come with F3 | #1, #3–#6, #43 bestiary | ok (fact sheets, no new mechanics) |
| tech | `docs/architecture.md` + interfaces with contract tests | **missing** (F6, F3; lead, level D); pipeline green (F5) | – | B tasks #11–#19 touch test files only, no module interface needed; no game-code B task goes out before F3/F6 |
| art | art bible: `docs/art/art_bible_p02_v01/ART_BIBLE.txt` | **outdated** (sword, human enemies); only palette and readability valid (brief S9); `docs/style-guide.md` missing | #7, #8 comic style guide | ok: text only, no asset task; comic assets wait for the chosen guide (E4) |
| audio | sound bible `docs/design/sound-bible.md` + event list | **missing** | – | ok: no audio task out |
| narrative | story outline + character sheets `docs/design/story.md` | **missing**; beats fixed in `docs/vision.md` („Geschichte“, „Comic“) | #9, #10 intro script | **went out before the gate**; acceptable because the four beats and the twist ban come verbatim from the vision and are in the acceptance criteria |
| ux | screen flow `docs/design/ux.md` + menu style guide + reference screen | style guide in progress (#38, #39); screen flow **missing**; reference screen E11.2 (lead) | #38, #39 | ok: these are the gate documents; E11.3–E11.9 wait for all three |
| qa | success criteria as checks: `docs/milestone-1.md` „Done means“, `docs/test-triage.md` | exists; `docs/qa.md` (severity scale, quarantine rules) missing | #11–#37 tests and diagnoses | ok |
| release | version scheme (SemVer, `0.1.0-prealpha`), platforms (G7), baseline package (S24) | decided | #40 CHANGELOG | ok |

Brief gate („brief and baseline package confirmed“): confirmed by neVs on 31.10.2026 (brief round 5). Gate documents still to write (S25): sound bible (2 variants), `docs/design/ux.md`, `docs/design/story.md`, `docs/style-guide.md`; lead: `docs/architecture.md` (F6), `docs/qa.md`.
