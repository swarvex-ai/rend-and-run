# Puzzle catalogue — factory

Catalogue of puzzle types for the factory route, for the post-M1 puzzle system (S8 "Inhalte als Daten": puzzles are data, no code touch required by contributors). Stance: **readable danger** — every trap announces itself, and no puzzle kills instantly except a pressure task. Inputs are gamepad-first with full keyboard parity (GDD §3): Interact = `E` / `Y`, movement = stick / D-pad, cancel = `Esc` / `B`. In-game UI texts stay German until the planned switch (project brief G10); puzzle ids and field names here are English.

Glossary terms used literally: **pressure task** (timed puzzle under threat of death), **sector** / **route** (`lab_route`, zone() in `modules/world/notstrom_layout.gd`: 01 / ARRIVAL, 02 / SERVICE, 03 / SUPPLY, 04 / SECURITY, 05 / AIRLOCK), **checkpoint**, **announcement**, **alarm**.

M1 note (S16): exactly one pressure task ships in M1 — the quick-maths door behind the Relay checkpoint (`puzzle_pressure_maths`, step 1). All other puzzle types below are post-M1.

## Puzzle types

### puzzle_wire_match — cable

**Goal:** Reconnect the severed power cable by matching coloured wire ends to terminals so the door motor runs.
**Inputs:** move the cursor between wire ends and terminals (stick / D-pad), attach with Interact (`E` / `Y`).
**Fail condition:** a wrong pairing pops the fuse — the door stays locked for ~15 s and an announcement plays once (no death).
**Difficulty ladder:**
1. 2 wires, colours match the terminal labels, static panel.
2. 4 wires; polarity marks (+ / −) must also match, and wire ends swap positions on reload.
3. 6 wires through a junction box — splice order matters, a wrong splice buzzes and resets the panel.
**First appearance:** 02 / SERVICE (maintenance wing fusebox door).

### puzzle_coolant_blend — colour

**Goal:** Blend the red / amber / teal coolant valves until the gauge shows the target warning hue.
**Inputs:** turn each valve wheel (hold Interact + rotate stick / D-pad), confirm the blend with Interact.
**Fail condition:** a wrong mix vents steam — the view is obscured for ~3 s and a maintenance drone investigates (no death).
**Difficulty ladder:**
1. One valve, teal target, gauge labelled.
2. Two valves, amber-to-teal blend, no labels.
3. Three valves, exact hue while the canister drips (time pressure, not lethal).
**First appearance:** 03 / SUPPLY (coolant tank room).

### puzzle_door_code — number

**Goal:** Read the door code hidden in the room and key it in to unlock the maintenance door.
**Inputs:** numeric keypad via stick / D-pad, confirm with Interact (`E` / `Y`), cancel with `Esc` / `B`.
**Fail condition:** a third wrong entry locks the keypad for ~10 s and triggers an alarm announcement (no death).
**Difficulty ladder:**
1. 3-digit code printed on a wall tag in the same room.
2. 4-digit code split across two visible clues (terminal + tag).
3. 5-digit code; one clue lies in the adjacent sector, so the code must be remembered.
**First appearance:** 04 / SECURITY (security wing door).

### puzzle_logic_arm — logic

**Goal:** Set the AND / OR / NOT levers so the output lamp matches the target pattern and arms the servo door.
**Inputs:** flip each lever with Interact (`E` / `Y`); read the output lamp against the target lamp.
**Fail condition:** wrong output buzzes and resets all levers to down; no damage.
**Difficulty ladder:**
1. One AND pair — both levers up for lamp on.
2. AND + OR chain of three levers, target shown.
3. NOT + AND + OR chain with one hidden input, revealed only after the first pull.
**First appearance:** 05 / AIRLOCK (airlock logic panel).

### puzzle_breaker_pulse — timing

**Goal:** Pull the breakers in sequence as their warning lights pulse to cut power to the hazard.
**Inputs:** press each breaker button with Interact (`E` / `Y`) when its light is on.
**Fail condition:** a mistimed pull restarts the sequence and sounds a local buzzer; the hazard stays live (no death).
**Difficulty ladder:**
1. 3 breakers, slow pulse, generous window.
2. 5 breakers, faster pulse, narrower window.
3. 7 breakers across two lanes with alternating pulse.
**First appearance:** 04 / SECURITY (power closet behind the security door).

### puzzle_valve_sequence — timing

**Goal:** Turn the steam valves in the numbered order before the pressure gauge redlines.
**Inputs:** turn valve wheels (hold Interact + rotate); the order is shown on the panel.
**Fail condition:** the wrong valve or a timeout vents steam — Rend is knocked back a step, no damage (no death).
**Difficulty ladder:**
1. 3 valves, numbers printed, slow pressure rise.
2. 5 valves, numbers fade after 3 s, faster rise.
3. 7 valves across two gauges, numbers shown only once.
**First appearance:** 02 / SERVICE (steam sublevel).

### puzzle_pattern_panel — logic

**Goal:** Replicate the light pattern on the panel by pressing its tiles in the shown sequence.
**Inputs:** move the cursor to a tile, press with Interact (`E` / `Y`).
**Fail condition:** a wrong tile resets the pattern; three resets sound the local alarm (no death).
**Difficulty ladder:**
1. 3-tile pattern, shown twice.
2. 5-tile pattern, shown once, tiles dim after being pressed.
3. 7-tile pattern in mirror mode (sequence entered in reverse).
**First appearance:** 05 / AIRLOCK (airlock code panel).

### puzzle_pressure_maths — timing — PRESSURE TASK (marked separately)

**Goal:** Solve the single-digit quick maths before the visible countdown ends to open the pressure door.
**Inputs:** numeric keypad via stick / D-pad, confirm with Interact (`E` / `Y`).
**Fail condition:** countdown reaches zero or a wrong answer = instant death. This is a pressure task: lethal by design, the only puzzle allowed to kill (glossary: "pressure task"). A checkpoint sits directly in front of the door (S19).
**Difficulty ladder:**
1. **M1 (ships now):** addition / subtraction, single-digit operands, 12 s countdown — matches `modules/world/pressure_task.gd` (`COUNTDOWN := 12.0`, operands 1–9, `*` restricted to 2–9).
2. Adds multiplication, 10 s countdown (S16 minimum).
3. Post-M1: mixed operators with two-digit operands, 8 s countdown.
**First appearance:** 04 / SECURITY (pressure door directly behind the Relay checkpoint, per S19).

## Pressure task fairness

The GDD (§6: "kein Permadeath", §2 lethal combat tone) and glossary define pressure tasks as timed puzzles under threat of death. The binding M1 fairness rules are in the project brief S16 (S7 scope: "1 Druck-Task"): announcement with tone + light before the task starts, a visible countdown of at least 10 s, single-digit maths in M1, failure = death, checkpoint directly in front, and retry cost ≤ ~20 s (G6: retry < 10 s). No non-pressure puzzle may kill instantly; every pressure-task death must feel earned because the threat was announced and the timing was generous.

## Curve table — route sector → puzzle id → step

| Route sector | Puzzle id | Step |
|---|---|---|
| 01 / ARRIVAL | — | — (first combat encounter, no puzzle) |
| 02 / SERVICE | puzzle_wire_match | 1 |
| 02 / SERVICE | puzzle_valve_sequence | 1 |
| 03 / SUPPLY | puzzle_coolant_blend | 1 |
| 04 / SECURITY | puzzle_door_code | 1 |
| 04 / SECURITY | puzzle_breaker_pulse | 2 |
| 04 / SECURITY | puzzle_pressure_maths | 1 (PRESSURE TASK, M1) |
| 05 / AIRLOCK | puzzle_logic_arm | 1 |
| 05 / AIRLOCK | puzzle_pattern_panel | 2 |
