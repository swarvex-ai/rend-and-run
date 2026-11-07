# Review: F3 route data and text table (lab_route.gd split)

Advisory review of the lead's split at base commit `591c86a`: texts in `game/data/route_texts.gd` (`b87ff54`) and placements in `game/data/route_layout.gd` (`541f5be`).

## Texts left

- `game/lab_route.gd:355` — `"ducken oder parieren"` / `"ducken"` in `hint.replace(...)`; known and intended, the base text comes from `game/modules/ui/combat_hint_text.gd`.
- No other player-visible German literal remains: all 93 `TEXT.t(...)` calls resolve 109 distinct keys, and the only non-table message parts are the language-neutral separators `" · "` (`game/lab_route.gd:965`) and the arrows `"←"` / `"→"` (`game/lab_route.gd:327`, `game/lab_route.gd:1171`).

## Placements left

Structural geometry (foundation, walls, ceiling, floor panels, door-leaf sizes) is excluded; I agree with that boundary.

- `game/lab_route.gd:120` — arena gate x offset `MISSION.BOSS_ENTRY_X - .35` is not in route data.
- `game/lab_route.gd:123` — service-return lift x offset `MISSION.EXIT_X + 1` is not in route data.
- `game/lab_route.gd:170` — fallback respawn `Vector3(0, 0.1, 0)` is a hardcoded checkpoint/spawn placement.
- `game/lab_route.gd:361` — coolant hint trigger uses literal `37.1` instead of `ROUTE.COOLANT_CANISTER_POS.x`; moving the canister in data silently breaks the cue.
- `game/lab_route.gd:380` — awakening blank y `2.35` and z `-0.55` are hardcoded around the data-driven x.
- `game/lab_route.gd:398` — awakening landing contact position y `.1`, z `-.55` is hardcoded.
- `game/lab_route.gd:400` — awakened robot z `-0.55` is hardcoded.
- `game/lab_route.gd:430` — first-salvage pickup y offset `+Vector3(0, .28, 0)` is hardcoded.
- `game/lab_route.gd:601` — cache plinth offset `+Vector3(0, 0.22, -0.45)` is hardcoded.
- `game/lab_route.gd:603` — armor display offset `+Vector3(0, 0.61, -0.45)` is hardcoded.
- `game/lab_route.gd:610` — shield display offset `+Vector3(0, 0.48, -0.2)` is hardcoded.
- `game/lab_route.gd:614` — workbench visual offset `+Vector3(0, 0, -0.55)` is hardcoded.
- `game/lab_route.gd:617` — entry workbench offset `+Vector3(0, 0, -.75)` is hardcoded.
- `game/lab_route.gd:620` — gun bench offset `+Vector3(0, 0, -.75)` is hardcoded.
- `game/lab_route.gd:623` — gun-bench label offset `+Vector3(-.25, .698, -.324)` is hardcoded.
- `game/lab_route.gd:625` — gun-bench lamp offset `+Vector3(0, 2.6, -.5)` is hardcoded.
- `game/lab_route.gd:628` — workbench label offset `+Vector3(-.25, .698, -.324)` is hardcoded.
- `game/lab_route.gd:632` — service-lamp y `3.2` and z `-1.65` are hardcoded although x comes from `ROUTE.SERVICE_LAMP_XS`.
- `game/lab_route.gd:636` — security-door x `MISSION.EXIT_X - 2` and y `1.6` are hardcoded (door-leaf size is out of scope).
- `game/lab_route.gd:672` — sentinel y `.05` and z `-2.3` are hardcoded; x comes from `factory_corridor.alcove_xs()`, not from route data.
- `game/lab_route.gd:704` — reinforcement spawn clamp x `1.0` / `MISSION.EAST_X - 2.0` and spacing `1.4` are hardcoded.
- `game/lab_route.gd:708` — reinforcement z offset `±0.5` and clamp `-1.0..1.2` are hardcoded.
- `game/lab_route.gd:741` — throwable crate y `+.31 + level * .63`, z `-.72` and x jitter `+.05` are hardcoded around the data-driven stack x.
- `game/lab_route.gd:772` — shard-pickup y offset `+Vector3(0, .28, 0)` is hardcoded.
- `game/lab_route.gd:828` — weapon-bench contact cue offset `+Vector3(0, 1.0, -.4)` is hardcoded.
- `game/lab_route.gd:979` — shortcut lift housing offset `+Vector3(0, 8.0, 0)` is hardcoded (borderline structural).
- `game/lab_route.gd:1206` — freight-cover y `.45`, z `0` and size are hardcoded although x comes from `ROUTE.FREIGHT_COVER_XS`.

## Changed values

Compared: 24 moved data declarations in `game/data/route_layout.gd` (49 individual placement/cue records); 0 differences found among the independently checkable values.

`git show 541f5be` could not be run because this checkout has no `.git` directory (checked with `find /work -name .git`). I therefore compared the new data values with the old values still documented or referenced in-repo: the route table in `docs/milestone-1.md:28-31`, the triage notes (`docs/test-triage/security_pair_test.md:33`, `docs/test-triage/duelist_footwork_test.md:45`), the coolant trigger still at `game/lab_route.gd:361`, and every call site. All documented values match, including 16.5, 18, 24, 26, 28.5, 37.1, 37.2, 40.8, 45.5, 51.5, 58, 62 and the PA cues 16.8/30.5/44.5/57.5/69. Values without an independent old-value source (throwable heights, freight-cover xs, service-lamp xs, cable position, drone y/z, reinforcement tables) are consistent with their call sites but cannot be proven equal to the removed literals without the commit.

## Other findings

- `game/lab_route.gd:633` — service-lamp tints are keyed to hardcoded `x == 26` and `x == 39`, so editing `ROUTE.SERVICE_LAMP_XS` changes which lamps are teal/amber.
- `game/lab_route.gd:856` — an internal English reason (`save_failed`, `install`, ...) can be appended to the German `shop_action_not_saved` text via `str(result.reason)`; this will surface untranslated strings in the UI.
- `game/lab_route.gd:1001` — the debug-only playtest jump hardcodes `x - 4.5`, y `.05`, z `0.0`; harmless for content but not driven by route data.
- `game/lab_route.gd:1053` — `_solid_footprint()` derives bodies from final transforms, so moving props in data keeps their collision footprint correct; no change needed.
- `game/tests/route_text_table_test.gd:15` — the regex-backed 109-key table contract passes; the tests `route_text_table_test` and `route_layout_test` were run green before writing this report.
