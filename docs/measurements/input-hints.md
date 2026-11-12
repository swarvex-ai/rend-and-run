# Input hints and gamepad bindings: inventory (E11.8 diagnosis)

Read-only diagnosis at base commit d33aec9. Nothing was run with a pad. Paths are relative to `game/` unless they start with `docs/`. "Pad" names follow Xbox layout (A=0, B=1, X=2, Y=3, Back=4, Start=6, L-stick click=7, LB=9, RB=10, D-pad 11-14).

Key finding: **all hints are hardcoded strings naming keyboard and pad together** ("E / Y"). Nothing reads the InputMap or the last used device. The `Q / LB` hint names a key that is bound nowhere.

## Part 1: player-facing hints that name an input

Device column: KB = keyboard, M = mouse, PAD = gamepad, BOTH = text lists KB and PAD. The text file is `data/ui_texts.gd` (UI) or `data/route_texts.gd` (RT). Shown-at is the code that displays it.

| # | Text key / literal | File:line | Text | Device | Shown at |
|---|---|---|---|---|---|
| 1 | `ammo_hud_reload` | UI:7 | `R — LADEN` | KB only (pad has L-stick click) | `modules/ui/ammo_hud.gd:61` |
| 2 | `arm_pickup_prompt` | UI:9 | `[E / Y] ARM BERGEN` | BOTH | `modules/world/arm_pickup.gd:30` (label hidden at :36, HUD prompt is used) |
| 3 | `equipment_back` | UI:20 | `Zurück · Esc / B` | BOTH | `modules/ui/equipment_menu.gd:28` |
| 4 | `equipment_hint` | UI:25 | `I / Select öffnet…; ↑↓ / Steuerkreuz und Eingabe / A wählen.` | BOTH | `modules/ui/equipment_menu.gd:51` |
| 5 | `hud_footer_narrow` | UI:51 | `F1 Hilfe · Esc Pause` | KB only | `modules/ui/combat_hud.gd:375` |
| 6 | `hud_footer_wide` | UI:52 | `I / Select Ausrüstung · F1 Hilfe · Esc / Start Pause` | BOTH (F1 has no pad) | `modules/ui/combat_hud.gd:303,375` |
| 7 | `hud_help_crouch_keys` | UI:56 | `C / Strg / RB` | BOTH | `modules/ui/combat_hud.gd:344` |
| 8 | literal `"A/D"` | `modules/ui/combat_hud.gd:339` | move | KB only | help panel |
| 9 | literal `"W/S / ↑↓"` | `modules/ui/combat_hud.gd:340` | depth | KB only | help panel |
| 10 | literal `"Space"` | `modules/ui/combat_hud.gd:341` | jump | KB only | help panel |
| 11 | literal `"J / X"` | `modules/ui/combat_hud.gd:342` | attack (X is the key X *and* pad X) | BOTH | help panel |
| 12 | literal `"Shift / K / B"` | `modules/ui/combat_hud.gd:343` | dodge (B is the pad button) | BOTH | help panel |
| 13 | literal `"E / Y"` | `modules/ui/combat_hud.gd:345` | interact | BOTH | help panel |
| 14 | `service_lift_call` | UI:108 | `E / Y — Aufzug rufen` | BOTH | `modules/world/service_return.gd:40` |
| 15 | `service_lift_down` | UI:109 | `E / Y — Aufzug abwärts` | BOTH | `modules/world/service_return.gd:42` |
| 16 | `service_lift_return` | UI:112 | `E / Y — Rückweg zum Kaltstart` | BOTH | `modules/world/service_return.gd:42` |
| 17 | `workbench_footer` | UI:130 | `Eingabe / A: wählen · Esc / B: zurück` | BOTH | `modules/ui/workbench_menu.gd:283` |
| 18 | `bench_prompt_install` | RT:13 | `E / Y — %s einbauen …` | BOTH | `lab_route.gd:832` |
| 19 | `bench_prompt_next_mod` | RT:14 | `Q / LB — nächstes Mod` | BOTH. **Bug:** the cycle is `Input.is_action_pressed("guard")` (`lab_route.gd:818`), i.e. L / RMB / LB. Q is bound to nothing. | `lab_route.gd:832` |
| 20 | `msg_arm_equipped` | RT:22 | `J / X: schlagen · zweimal drücken…` | BOTH | `lab_route.gd:1235` |
| 21 | `msg_checkpoint_save_failed` | RT:27 | `…Erneut E / Y versuchen.` | BOTH | `lab_route.gd:313` |
| 22 | `msg_gun_taken` | RT:35 | `Nachladen: R · Waffen wechseln: 1–4 / Mausrad` | KB/M only (pad: reload L-stick click, next-weapon Back; no hint) | `lab_route.gd:276` |
| 23 | `msg_shield_tutorial` | RT:48 | `L / RMB / LB halten` | BOTH (KB, M, PAD) | `lab_route.gd:800` |
| 24 | `prompt_carry_crate` | RT:77 | `Angriff — Kiste werfen · E / Y — absetzen` | BOTH (the word "Angriff" names an action, not a key) | `lab_route.gd:278` |
| 25 | `prompt_checkpoint` | RT:78 | `E / Y — Kontrollpunkt …` | BOTH | `lab_route.gd:306` |
| 26 | `prompt_lift_crate` | RT:80 | `E / Y — Kiste aufheben` | BOTH | `lab_route.gd:281` |
| 27 | `prompt_recover_shards` | RT:81 | `E / Y — %d verlorene Splitter …` | BOTH | `lab_route.gd:252` |
| 28 | `prompt_relay_secure` | RT:83 | `E / Y — Relais sichern …` | BOTH | `lab_route.gd:292` |
| 29 | `prompt_take_arm` | RT:84 | `E / Y — Humanoidenarm …` | BOTH | `lab_route.gd:249` |
| 30 | `prompt_take_armor` | RT:85 | `E / Y — Laborpanzer anlegen …` | BOTH | `lab_route.gd:284` |
| 31 | `prompt_take_gun` | RT:86 | `E / Y — %s aufnehmen · Feuern: U / linke Maustaste / RT` | BOTH (KB, M, PAD) | `lab_route.gd:268` |
| 32 | `prompt_take_salvage_shield` | RT:87 | `E / Y — Schrottschild aufnehmen` | BOTH | `lab_route.gd:288` |
| 33 | `prompt_take_shield` | RT:88 | `E / Y — %s aufnehmen%s` | BOTH | `lab_route.gd:259` |
| 34 | `prompt_workbench_open` | RT:91 | `E / Y — Werkbank öffnen` | BOTH | `lab_route.gd:303` |
| 35 | literal F1 handler (no text) | `lab_route.gd:218` | opens help | KB only, no pad action | key event |
| 36 | literal `KEY_PAGEDOWN` handler | `lab_route.gd:222` | debug/door shortcut, no text | KB only | key event |

Hits for "Taste/press/Button" in the two text files that name **no** input (checked, not hints): `msg_switch_after_action` (RT:50, "Angriff / Abwehr" are actions), `advice_*`, `hint_*` (UI:43-50, they name moves, not inputs), `hud_help_*` labels (UI:54-62, action names only; the key column is in rows 7-13), `equipment_back` button text is row 3. `[E] Konsole` appears only in tests (`tests/combat_hud_preview.gd:18`, `tests/combat_hud_test.gd:81`).

Not hints, but hardcoded device names in comments/docs: `modules/ui/menu_screen.gd:9-10`, `modules/ui/pause_menu.gd:6`, `modules/ui/start_menu.gd:4`, `modules/ui/options_menu.gd:4`.

## Part 2: actions and bindings

Source: `project.godot` `[input]` (line = action definition), code-created actions, and raw events. All code-created events leave `device` at the engine default (as documented in `docs/design/ux.md:95`).

| Action | Defined at | Keyboard / mouse | Gamepad | Gap? |
|---|---|---|---|---|
| `move_left` | project.godot:26 | A, Left arrow | left stick X−, D-pad left | |
| `move_right` | project.godot:30 | D, Right arrow | left stick X+, D-pad right | |
| `move_up` (depth) | project.godot:51 | W, Up arrow | left stick Y−, D-pad up | |
| `move_down` (depth) | project.godot:55 | S, Down arrow | left stick Y+, D-pad down | |
| `jump` | project.godot:34 | Space | A | |
| `attack` | project.godot:38 | J, X | X | |
| `dodge` | project.godot:43 | Shift, K | B | |
| `crouch` | project.godot:47 | C, Ctrl | RB (button 10) | |
| `restart` | project.godot:59 | R | **none** | **no pad**; R also = reload (conflict), used at `main.gd:112` |
| `interact` | `lab_route.gd:210-215` | E | Y | defined only when the route exists (not in project.godot) |
| `guard` | `player.gd:149-156` | L, right mouse | LB | |
| `weapon_1`..`weapon_4` | `player.gd:157-161` | keys 1-4 | **none** | **no pad** |
| `weapon_next` | `player.gd:162-166` | mouse wheel down | Back | Back also opens equipment (`pause_controller.gd:75`): conflict |
| `weapon_prev` | `player.gd:162-165` | mouse wheel up | **none** | **no pad**, no keyboard either |
| `reload` | `player.gd:167-171` | R | left stick click | R shared with `restart` |
| `fire` | `player.gd:172-177` | U, left mouse | right trigger (axis, deadzone 0.4) | |
| `dash` | referenced only in `pause_controller.gd:11` | n/a | n/a | **action does not exist** (guarded by `has_action`); dead entry |
| `ui_up/down/left/right/accept/cancel` | engine built-ins (not in project.godot) | arrows, Enter, Space, Esc | D-pad/stick, A, B | used by `modules/ui/menu_screen.gd:217` |

Raw events outside the InputMap (no action, hence not remappable and not readable by a glyph lookup):

| Input | File:line | Keyboard | Gamepad | Gap? |
|---|---|---|---|---|
| Pause | `pause_controller.gd:78-79` | Esc | Start | |
| Cancel in pause UI | `pause_controller.gd:60` | Esc | B, Start | |
| Menu navigate | `pause_controller.gd:66-69` | n/a | D-pad up/down, A | |
| Equipment overview | `pause_controller.gd:75` | I | Back | shares Back with `weapon_next` |
| Help panel | `lab_route.gd:218` | F1 | **none** | **no pad** |
| Debug shortcut | `lab_route.gd:222` | PageDown | none | debug only |

Actions without any gamepad binding: `restart`, `weapon_1`-`weapon_4`, `weapon_prev`, help (F1). Back is double-bound (`weapon_next` + equipment overview).

## Part 3: proposal

### One place for labels

Add `modules/ui/input_glyphs.gd` (a `RefCounted` with static functions, no new autoload, see AGENTS.md):

- `label(action: String, device: int) -> String`: reads `InputMap.action_get_events(action)`, picks the first event of the requested device kind (keyboard/mouse or pad), and maps it to a short label (`E`, `Space`, `RMB`, `Y`, `RT`, `LB`). Keyboard labels come from `OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(...))`; pad labels come from a constants table (`JOY_BUTTON_* → "A"…`), kept in data per AGENTS.md.
- `last_device` tracking: a small node `modules/ui/input_device_tracker.gd` owned by `main.gd` (not an autoload) watches `_input` and emits `device_changed(kind)` for key/mouse vs joypad button/axis (axis only above deadzone), and for `Input.joy_connection_changed`.
- Texts get placeholders, e.g. `"{interact} — Werkbank öffnen"` in `route_texts.gd`; `InputGlyphs.format(text)` replaces `{action}`. This also fixes row 19 (`{guard}` instead of the unbound Q).
- Mixed lists (rows 7, 11-13, 22, 23, 31) become per-device text in the same placeholder form.

### Follow-up B tasks (each under 300 lines)

1. **Glyph lookup module + test.** New `modules/ui/input_glyphs.gd`, `tests/input_glyphs_test.gd`. Label table for keys, mouse, pad buttons, axes; `format()` for `{action}`. No call sites yet.
2. **Last-device tracker + hot-plug.** New `modules/ui/input_device_tracker.gd`, small hook in `main.gd`, `tests/input_device_tracker_test.gd`. Emits `device_changed`; handles `joy_connection_changed` (unplug falls back to keyboard).
3. **Move route prompts to placeholders.** `data/route_texts.gd` (rows 18-34), `lab_route.gd` prompt callers, `modules/world/service_return.gd`, `data/ui_texts.gd` rows 2, 14-16; formatted at display time, refreshed on `device_changed`. Fixes the Q/LB hint (row 19).
4. **HUD footer, help panel and menu footers.** `modules/ui/combat_hud.gd:299-375` (rows 5-13, literal key strings into `ui_texts.gd`), `modules/ui/ammo_hud.gd`, `modules/ui/equipment_menu.gd`, `modules/ui/workbench_menu.gd` (rows 1, 3, 4, 17).
5. **Missing gamepad bindings (needs a neVs decision, see `docs/design/ux.md:113`).** `player.gd:157-177` adds pad events for `weapon_1`-`weapon_4`/`weapon_prev` and resolves the Back conflict; `restart` pad binding (project.godot is protected, so add in code like `guard`, or lead edits it); remove dead `dash` from `pause_controller.gd:11`; `tests/pad_bindings_test.gd`. Design decision first: which buttons, and whether Back stays on equipment.
6. **Route raw events through actions.** `pause_controller.gd:60-79` and `lab_route.gd:218` (help, pause, equipment) become actions (`pause`, `equipment`, `help`) so the glyph lookup can read them and F1 gets a pad binding; `tests/pause_integration_test.gd` stays green.

Order: 1, 2, then 3 and 4 in parallel; 5 and 6 are independent of the rest but 5 waits for neVs.
