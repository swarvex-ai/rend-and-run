# 0004: Where player-visible texts live (preparation for E5)

- Status: accepted · 07.11.2026 · decided by the lead (an interface inside the approved architecture, LEAD.md 1.3; no change to vision, scope or licence)
- Context: E5 moves the in-game texts to English. The route's texts are already in one table, `game/data/route_texts.gd` (F3, #50), protected by `route_text_table_test`. Review #107 (`docs/reviews/e5-text-literals-in-tests.md`) found 27 test comparisons with German literals that live in other game scripts: `game/modules/ui/sector_complete.gd`, `workbench_menu.gd`, `overseer_status.gd`, `combat_hint_text.gd`, `game/modules/world/checkpoint_console.gd`, `notstrom_layout.gd` (zone labels), `game/modules/combat/gun.gd` (`MODS` labels), `lab_overseer.gd` (role label). A translation would have to touch each of those scripts, and their tests would break on every word.

## Decision

1. **A second table for module texts: `game/data/ui_texts.gd`.** It has the same shape and API as `route_texts.gd` (`const TEXTS := {key: text}`, `static func t(key) -> String`, `static func keys() -> Array`, unknown key → `push_error` and the key itself). Keys are English `snake_case`, prefixed by the owning script (`sector_complete_saved`, `checkpoint_ready`, `zone_supply`, `gun_mod_laser`, …). Values stay German until E5 changes only the values.
2. **`route_texts.gd` stays as it is** and keeps serving `lab_route.gd` only. Its contract test scans `lab_route.gd`; mixing module texts into it would break that contract.
3. **A contract test `ui_text_table_test`** (headless) does for `ui_texts.gd` what `route_text_table_test` does for the route: every `UI_TEXT.t("key")` used in `game/modules/**/*.gd` resolves, every table key is used somewhere in `game/modules/**`, and no text is empty. Module scripts load the table as `const UI_TEXT = preload("res://data/ui_texts.gd")`. Correction 07.11. evening: a second load-order dependency is still open (diagnosis #111), so every task that adds a `preload` runs `first_room_playthrough` and `farming_input_playthrough`; if they turn red, use `load()` at the call site until #111 is fixed.
4. **Tests compare through the table**, never through a typed German string: `TEXT.t("key")` for route texts (task #108), `UI_TEXT.t("key")` for module texts.
5. **Order of work (E5):** (a) #108 switches the 14 route-text comparisons; (b) the table plus contract test, with the first module moved (`sector_complete.gd`, 7 hits); (c) one task per remaining module, each moving its literals and switching its tests; (d) only then the English values, in both tables, as one text task. Addendum 08.11.: a full scan found 44 German texts outside the tables that no test compares (HUD, pickups, world, pause, start); steps 3g (#120) and 3h (#121) move them before (d). The contract test also scans the core scripts directly under `res://` since `bbcaca9`.

## Consequences

- Translating is a change to two data files; no test breaks because of the wording.
- Formatting stays with the caller (`UI_TEXT.t("workbench_missing_shards") % n`), as in the route table.
- Robot voice lines and PA texts (`robot_voice.gd` `LINES`/`PA`) belong to the story gate (message 18) and the voice files; they are not moved before neVs approves the story outline.
