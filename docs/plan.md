# Plan

> Maintained by the lead. Milestone spec: `docs/milestone-1.md`. Status of each session: `docs/status.md`.

## Baseline: solo build until 30.10.2026

One agent (Claude) built Rend&Run alone in 24 calendar days, up to the public release `3b3f444` (28.10.) plus the lead foundation of 30.10. This is the starting point of the swarm, not a milestone (decision neVs, message 3, 02.11.2026). The swarm balance compares task units (level weights as in progress: A 1, B 2, C 3, D 5), not the duration of M1 against the 24 days, and no estimated hours.

| Area | State at the baseline | Size (at `3b3f444`) |
|---|---|---|
| Features | route V12: five zones, six robot types (guard, shield bearer, sentinel, dog, drone, overseer), robot arm, pistol, smg, scattergun, energy rifle, shield, throwable crates, shards, death cache, workbench and weapon bench, two checkpoints, boss arena; details: `docs/milestone-1.md` „The route today“ | 114 GDScript files, 14,115 lines |
| Tests | 77 headless green; 28 quarantined (`docs/test-triage.md`); no playthrough test | 133 test files, 9,708 lines |
| Tools | asset, voice and test scripts | 41 scripts, 3,851 lines |
| Assets | generated models, textures, sounds and motion, with provenance | 84 GLB, 78 PNG/JPG, 51 WAV, 17 generated motion resources |
| Docs | GDD, scope, art bible P02 (partly outdated: sword, human enemies) | 24 files, ~12,800 words |
| Not yet there | English text, intro comic, pressure task, tells ≥ 0.5 s checked, accessibility toggles, menus and baseline package (E11), Windows export, timed playtests | – |

### The baseline in task units

How the lead would have sliced `3b3f444` as swarm tasks, by the same rules as real tasks (LEAD.md 6.1–6.2: B ≤ 300 lines and 1–5 files behind a finished interface, C inside a system, D cross-cutting; tests are part of each task, not counted separately). Counted is only what exists at `3b3f444`, including later outdated parts (sword, chaser); discarded iterations are not counted, so the value is a lower bound.

| Building block | Tasks | Level | Units | Reason |
|---|---|---|---|---|
| Walking skeleton, game loop, pause, `FX` autoload (`main.gd`, `start.gd`, `pause_controller.gd`, `fx.gd`) | 1 | D | 5 | defines scene flow and the only singleton |
| Player architecture (`player.gd`: states, input, damage interface) | 1 | D | 5 | interface every robot, weapon and HUD depends on |
| Robot base and state machine (`enemy.gd`: roles, attack phases) | 1 | D | 5 | base class of all robot types |
| Route system (`lab_route.gd`, `notstrom_layout.gd`: zones, encounters, checkpoints) | 1 | D | 5 | data model of the whole level |
| Combat contact and damage model (`hit_physics`, `blade_contact`, `attack_cadence`, hit stop) | 1 | D | 5 | shared by player and all robots |
| Persistence and save format (`atomic_json_writer`, migration, save guard) | 1 | D | 5 | data model; migration must stay compatible |
| Test runner, headless harness, manifest, asset validation (`tools/`) | 1 | D | 5 | the test contract |
| Squad behaviour (`squad_director`, `guard_state`, `guard_spacing`) | 1 | C | 3 | inside the robot system, 351 lines in 3 files |
| Shield bearer (role 1 in `enemy.gd`) | 1 | C | 3 | changes the shared state machine |
| Overseer boss (`lab_overseer`, `overseer_low_pose`, role 2) | 1 | C | 3 | inside the robot system, two phases |
| Equipment and workbench economy (`equipment_ledger`, `item_catalog`) | 1 | C | 3 | touches save format and player stats |
| Checkpoints and respawn (`checkpoint_console`, route hooks) | 1 | C | 3 | inside the route system |
| Robots breaking apart (`articulated_death`, `death_fragments`, `quadruped_death`, `debris`) | 1 | C | 3 | changes every robot's death path |
| Player melee chain (robot arm combo inside `player.gd`) | 1 | C | 3 | inside the player system |
| Route content zones 01–03 and zones 04–05 (placements, PA cues) | 2 | C | 6 | inside the route data, one task per zone group |
| Player: movement and jump, dash, crouch, damage/bleeding/death, gun handling + ammo HUD, gun hold pose | 6 | B | 12 | isolated parts behind the player interface |
| Robots: gun guard, pulse guard, sentinel, dog, drone, energy bolt, attack cues (tells), recovery step | 8 | B | 16 | one type or one behaviour behind the robot base |
| Interactables: welding arm, security camera, alarm sequence + beacon + flicker, coolant canister, throwable crate, supply crate, shard pickup, arm/gun/shield pickups, arena gate, shortcut door, service return + wayfinding, death cache | 12 | B | 24 | one module each, 20–200 lines |
| Frozen economy: servo trial + run ledger, prefix ledger | 2 | B | 4 | isolated modules |
| UI: start menu, pause menu, sector complete, combat HUD (2, 374 lines), workbench menu (2, 383 lines), equipment menu, overseer status, edge threat indicator, feedback priority + hints | 11 | B | 22 | one screen or widget each; files over 300 lines count twice |
| VFX: blood spray, metal and impact sparks, slash trail + dash streaks, landing dust, explosion + gun FX | 5 | B | 10 | one effect family each |
| Visuals: blade and cleaver visuals, canister visual, small prop visuals (2) | 4 | B | 8 | one visual family each |
| World: clean factory, factory corridor, assembly line + calibration, power sector, foreground + floor markings + atmosphere | 5 | B | 10 | one set piece each |
| Audio code: ambience + foot contact clock, robot voice | 2 | B | 4 | isolated modules |
| Tools: clip retargeting, motion baking, voice generation | 3 | B | 6 | one script each |
| 3D models: 8 characters, 13 weapons and props, 24 environment pieces | 45 | A | 45 | one asset brief per model (variants like `_baked`/`_arm` folded in) |
| Motion sets: hero, light humanoid, heavy humanoid, dog, hit reactions | 5 | A | 5 | one asset brief each |
| Sound: voice lines (37, 3 batches), effects and ambience (14, 3 batches) | 6 | A | 6 | batches of 5–15 files |
| Textures and atlas | 2 | A | 2 | atlas, environment finish |
| Design docs: GDD, art bible P02, scope, asset specification | 4 | A | 4 | one document each |
| Balancing and playtest runs | 3 | A | 3 | simulation or playtest report |
| **Sum** | **139** | | **243** | D 7 · C 9 · B 58 · A 65 |

**M1 is the increment on top:** everything under „Content in M1“ and „Done means“ in `docs/milestone-1.md` that the table marks as not yet there, plus all quarantined tests back to green (criterion f).

## M1: the first escape route

### Phase F: foundation (lead, level D) — blocks all code tasks

| ID | Work | State | Unblocks |
|---|---|---|---|
| F1 | milestone-1.md, plan, status, ADR 0001 | done 30.10. | everything |
| F2 | triage the 28 quarantined tests (`docs/test-triage.md`); dash_visual_test promoted to headless | done 30.10. | E1 |
| F3 | split `lab_route.gd`: route data (encounters, props, PA cues, checkpoints) and a text table as extension points — task #50 | done 05.11. (`b87ff54` texts in `game/data/route_texts.gd`, `541f5be` placements in `game/data/route_layout.gd`, contract tests; review #59) | E3, E5, E6, E7 |
| F4 | headless test `route_playthrough`: start → airlock (criterion a) and retry < 10 s (c) — task #51 | done 06.11. (deterministic, 3 identical runs; route in 20.6 s, control back after 2.43 s game time) | E2, E9 |
| F5 | `swarvex env` green without network (77/77, 3 min); `.agents/**` protected; runner: `--headless` for named/quarantined tests, named runs fail on red | done 30.10. | first code task |
| F6 | `docs/architecture.md` (module map, extension points); `docs/qa.md` (severity scale, quarantine rules). The art bible is task #48 instead of a lead stub — task #49 | done 05.11. | B tasks |

### Running now (level A, no code dependency)

| Task | Title | State |
|---|---|---|
| #1, #3–#6, #43 | bestiary pages: guard, sentinel, dog, drone, overseer; shield bearer #43 (replaces #2) | open |
| #7, #8 | comic style guide proposal, variants 1/2 and 2/2 | open |
| #9, #10 | intro comic script, variants 1/2 and 2/2 | open |

### Epics after the foundation (sliced once F2–F4 are done)

| Epic | Content | Depends on |
|---|---|---|
| E1 | M1 tests green: one repair task per quarantined test kept by F2. 05.11.: #11–#16 and #18 accepted and out of quarantine (ranged stays in: flaky); #19 found the machinery chamber is gone (retire or restore at milestone review); new repairs #54 first_room_playthrough, #55 ranged crouch check, #56 landing headless; 06.11.: #17 accepted (shortcut out of quarantine), diagnoses #20–#26 accepted, repairs #65 arena gate, #66 overseer, #67 persistence, #68 shard pickup, #69 service return, #70 B-close dodge bug (after #64), #71 workbench (after #70), #72 route_v12, #58 depth_test; afternoon: #54 accepted (first_room_playthrough out of quarantine), #85 back for rework, #55 replaced by #91 (no preload in hook tests), diagnosis #90 load-order dependency of the first melee fight; evening: #85 accepted (shop_close_input_test registered), #58 accepted (depth_test out of quarantine), #65 accepted (arena_gate_integration out of quarantine), #67 and #68 accepted (both out of quarantine), #66 accepted after rework (stays in quarantine, low-blade check red), diagnosis #93; #69 accepted (service_return out of quarantine); #61 menu fonts rework (provenance); #72 accepted (route_v12_test out of quarantine); #73 accepted (coolant_test out of quarantine); #61 accepted, fonts replaced with official release files; 07.11.: #79 and #80 accepted (pressure_step_test, guard_spacing_test, edge_warning_test out of quarantine), #81 accepted (projectile_lifetime_test out of quarantine), #82 accepted (guard_integration_test, feedback_priority_integration out of quarantine), #83 accepted (security_pair_test, duelist_footwork_test out of quarantine); #94 closed as duplicate of #79; #84 accepted (brute_commitment_test), #85 accepted (E11.5b pause menu checks); projectile_lifetime_test back in quarantine (flaky), diagnosis #95; #86 accepted; brute_commitment_test and workbench_integration out of quarantine; #87 accepted (E11.4b main menu checks, start_options_test registered), #88 accepted (attack_cue heavy check hits a plain brute), #89 accepted (ranged_integration_test out of quarantine), #90 accepted (robot_voice_bus_test registered), diagnosis #93 accepted, fix #96 accepted (overseer_integration out of quarantine), diagnosis #95 accepted, fix #97 accepted (projectile_lifetime_test out of quarantine); only machinery_chamber_integration left (milestone review); F3 review #59 accepted, follow-up #98; load-order diagnosis #90 → fix #104 accepted (deterministic lanes, enemy_lane_assignment_test) | F2 |
| E2 | timing and route length (S23): playtests, then extend or cut | F4, playtests |
| E3 | pressure task: quick-maths door after the relay checkpoint | F3 |
| E4 | intro comic: pick script + style (neVs) → asset brief preview → final → in-game player | #7–#10 |
| E5 | English in-game text from the text table. 07.11.: #107 inventory accepted (41 hits); decision 0004 (ui_texts.gd for module texts); #108 route-text comparisons via TEXT.t(), #110 ui_texts.gd + contract test + sector_complete (accepted); #112 checkpoint/overseer labels (accepted) → #113 zone labels → #115 workbench menu → #116 combat hints → #117 gun and mod names → #119 item catalogue and equipment menu (replaces #118) → #120 HUD, ammo and pickup texts → #121 world, pause and start texts (08.11.: full scan found 44 more German texts outside the tables) (serial, shared table; #112, #113, #115, #116, #117 accepted); English values last | F3 |
| E6 | accessibility: subtitles, slow-motion and screen-shake toggles, alarm ≤ 3 Hz. 07.11.: #99 settings apply at start + shake/slow-motion toggles, #100 subtitles toggle (after #99), #101 alarm ≤ 3 Hz contract test; #99, #100 and #101 accepted, tests registered (E6 done in code; check in the playtest) | F3 |
| E7 | readable danger: every tell ≥ 0.5 s (from bestiary gaps), boss 60–150 s. 07.11.: measurement #106 accepted: 4 of 18 attacks at 0.483 s (role-1 windup 0.40 s), question to neVs (message 20) | #1–#6, E1 |
| E8 | Windows export + smoke test | F5 |
| E9 | performance measurement on the reference PC | F4 |
| E10 | sign-off: playtests neVs + 2 fresh eyes, credits, itch.io slice | all |
| E11 | menus and baseline package (brief „Grundpaket“, S24): see below | F3 (texts), E11.2 |

Critical path: F2 → F3 → F4 → E1/E3/E7 → E2 → E10.

Estimate 08.11.2026 (`estimate_milestone`): M1 needs about 140 tasks in all (104 done, 107 planned). Not cut yet: E2 2–4, E3 2–3, E4 3–4, E5 d 1–2, E7 1–2, E8 1–2, E9 1, E10 3–4, E11 rest 5–8, follow-ups from messages 13–20 4–6, plus about 20 % buffer. Update the estimate whenever the plan changes.

### E11: menus and baseline package

Reference first, then copies. Existing items are mapped, not duplicated: G-5 → E6, G-14 → F3/E5, B5 → E8, G-7 corrupt save → diagnosis #22, G-8/G-9 → E10 playtests, G-10 retry → F4.

| ID | Work | Level | Depends on |
|---|---|---|---|
| E11.1 | menu style guide, variants 1/2 and 2/2 (`design.ui`, text + mockup description); neVs picks one — tasks #38, #39 | A | – |
| E11.2 | reference menu screen „Options“ (lead, extension point): `MenuScreen` base with transitions, focus animation, UI sounds, back handling; settings store (`user://settings.cfg`, separate from progress); audio buses Music/Voice; contract test — task #52, done 06.11. (`0d8787f` settings store, `8622049` MenuScreen + Options; follow-ups #60 voice bus, #61 fonts, #62 menu_back.wav) | D | E11.1 pick, F3 text table |
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

The lead plays all roles (virtual officers); cards: `lead/roles/game/*.md` in swarvex-ai/swarvex. Every new task names its `role`. Lead D work runs as tasks #49–#52, closed with `complete_own_task` (shown as done by the lead without peer review, not in the four-eyes rate); larger ones (F3, E11.2) then get an advisory review task. Checked 31.10.2026.

| Role | Gate document | State | Open tasks (role) | Gate |
|---|---|---|---|---|
| game-design | `docs/milestone-1.md` (M1 rules, route), `docs/gdd.md` (historical core loop) | exists; level briefs and balance-as-data come with F3 | #1, #3–#6, #43 bestiary | ok (fact sheets, no new mechanics) |
| tech | `docs/architecture.md` + interfaces with contract tests | `docs/architecture.md` exists (F6, 05.11.); route data and text table still missing (F3; lead, level D); pipeline green (F5) | – | B tasks #11–#19 touch test files only, no module interface needed; no game-code B task goes out before F3/F6 |
| art | art bible: `docs/art/art_bible_p02_v01/ART_BIBLE.txt` | **outdated** (sword, human enemies); only palette and readability valid (brief S9); renewal as `docs/style-guide.md` is task #48 | #7, #8 comic style guide, #48 | ok: text only, no asset task; comic assets wait for the chosen guide (E4) |
| audio | sound bible `docs/design/sound-bible.md` + event list | **missing**; variants #45, #46 | #45, #46 | ok: no audio task out |
| narrative | story outline + character sheets `docs/design/story.md` | **missing**; task #47; beats fixed in `docs/vision.md` („Geschichte“, „Comic“) | #9, #10 intro script, #47 | **went out before the gate**; acceptable because the four beats and the twist ban come verbatim from the vision and are in the acceptance criteria |
| ux | screen flow `docs/design/ux.md` + menu style guide + reference screen | style guide in progress (#38, #39); screen flow task #44; reference screen E11.2 (lead) | #38, #39, #44 | ok: these are the gate documents; E11.3–E11.9 wait for all three |
| qa | success criteria as checks: `docs/milestone-1.md` „Done means“, `docs/test-triage.md` | exists; `docs/qa.md` (severity scale, quarantine rules) exists since 05.11. | #11–#37 tests and diagnoses | ok |
| release | version scheme (SemVer, `0.1.0-prealpha`), platforms (G7), baseline package (S24) | decided | #40 CHANGELOG | ok |

Brief gate („brief and baseline package confirmed“): confirmed by neVs on 31.10.2026 (brief round 5). Gate documents still to write (S25): sound bible (2 variants), `docs/design/ux.md`, `docs/design/story.md`, `docs/style-guide.md`; lead: `docs/architecture.md` and `docs/qa.md` done 05.11. (F6).
