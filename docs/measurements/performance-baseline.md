# E9: Route Performance Baseline (Physics Step & Node/Draw Budget)

## Sandbox Limitation & Methodology Notice

**IMPORTANT:** All measurements recorded in this document were collected in a **software-rendered, headless test sandbox** (Godot 4.7.2 with `--headless`, `--audio-driver Dummy`, and `--fixed-fps 60` on Linux CI container). They do **NOT** represent the reference gaming PC.

Specifically:
- Rendering draw calls and primitive counts (`Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME`) report `0` on the headless dummy renderer because no visual rendering pipeline or draw submission is executed.
- `Performance.PHYSICS_3D_ACTIVE_OBJECTS` reports `0` under Jolt Physics when headless monitoring is queried via `Performance.get_monitor()`.
- Physics step time (`Performance.TIME_PHYSICS_PROCESS`) measures the CPU duration of the physics tick within the container environment, including scene instantiation spikes and software-scheduled steps.

Measurement probe script: `game/tests/perf_probe.gd`, which executes the full route traversal matching `game/tests/route_playthrough.gd` (scripted death, respawn, route traversal through encounters, door interactions, jumps, and completion at the airlock exit).

Run command:
```bash
tools/run_tests.sh perf_probe
```

---

## Per-Zone Measurement Table

The route consists of 5 authored zones defined in `modules/world/notstrom_layout.gd`:
1. `01 / ANKUNFT` (Arrival: $x < 11.0$)
2. `02 / WARTUNG` (Maintenance: $11.0 \le x < 24.0$)
3. `03 / VERSORGUNG` (Supply: $24.0 \le x < 29.5$)
4. `04 / SICHERUNG` (Security: $29.5 \le x < 70.0$)
5. `05 / SCHLEUSE` (Airlock Exit: $x \ge 70.0$)

The table below records metrics at the busiest moment of each zone, as well as the average and maximum physics step times observed across all frames sampled in that zone.

| Zone | X Span (m) | Samples (frames) | Max Active Enemies | Max Physics Bodies (`PHYSICS_3D_ACTIVE_OBJECTS`) | Max Nodes Alive | Peak Moment X (m) | Peak Game Time (s) | Physics Step Time (avg ms) | Physics Step Time (max ms) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| **01 / ANKUNFT** | $x < 11.0$ | 107 | 9 | 0* | 3,227 | 3.32 | 0.02 | 1,371.954** | 12,086.001** |
| **02 / WARTUNG** | $11.0 \le x < 24.0$ | 167 | 11 | 0* | 3,507 | 20.86 | 3.63 | 8.058 | 18.601 |
| **03 / VERSORGUNG** | $24.0 \le x < 29.5$ | 176 | 10 | 0* | 3,824 | 26.86 | 5.85 | 3.020 | 3.020 |
| **04 / SICHERUNG** | $29.5 \le x < 70.0$ | 643 | 10 | 0* | 4,003 | 36.40 | 9.27 | 11.545 | 15.457 |
| **05 / SCHLEUSE** | $x \ge 70.0$ | 307 | 3 | 0* | 3,834 | 70.12 | 18.25 | 15.055 | 19.136 |

\* Under Jolt 3D physics in Godot 4.7.2 headless mode, `Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)` reports `0`.
\*\* Zone 01 contains the initial scene instantiation and shader/pipeline warm-up spike immediately following respawn. Once settled, steady-state physics ticks in Zone 01 run under 8.0 ms.

---

## The 3 Busiest Moments on the Route

1. **Encounter Pack at Security Wing Entry ($x \approx 36.40$ m, $t \approx 9.27$ s, Zone: `04 / SICHERUNG`)**
   - **Metrics:** 9 active enemies alive, 3,954 nodes, physics step: 7.884 ms (reaches peak node count of 4,003 at $t = 9.33$ s).
   - **Cause:** Convergence of assembly line encounters, awakening humanoids, and dog/smg guards within active detection radii.

2. **Supply / Maintenance Transition ($x \approx 20.86$ m to $26.86$ m, $t \approx 3.63$ s to $5.85$ s, Zones: `02 / WARTUNG` & `03 / VERSORGUNG`)**
   - **Metrics:** 10–11 active enemies, 3,507–3,824 nodes, physics step: 3.020–18.601 ms.
   - **Cause:** Maintenance corridor robots awake and pursuing Rend toward the first workbench and checkpoint console while props and crates remain loaded.

3. **Airlock Gate & Boss Arena Entry ($x \approx 70.12$ m, $t \approx 18.25$ s, Zone: `05 / SCHLEUSE`)**
   - **Metrics:** 2–3 active boss/elite enemies, 3,834 nodes, physics step: 9.855 ms (zone max: 19.136 ms).
   - **Cause:** Boss arena setup, gate locks, and collision bounds initialization for the Brute encounter.

---

## Proposed Thresholds for a Later Contract Test

Based on these baseline measurements, the following limits are proposed for a future automated contract/budget test (excluding initial 1-second scene boot spikes):

1. **Node Budget:**
   - **Threshold:** $\le 4,500$ nodes alive at any point on the route (current peak: 4,003 nodes).
   - **Rationale:** Ensures prop streaming, enemy destruction, and FX pooling do not leak nodes across room transitions.

2. **Active Enemy Population Budget:**
   - **Threshold:** $\le 14$ simultaneously active enemies (current peak: 11 enemies in Zone 02).
   - **Rationale:** Prevents AI update and combat query explosions if off-screen reinforcement triggers stack.

3. **Steady-State Physics Step Time (Headless / Sandbox):**
   - **Threshold:** $\le 25.0$ ms per physics tick after the first 60 frames (current steady-state max: 19.14 ms).
   - **Rationale:** A 60 Hz physics step budget is nominally 16.67 ms on target hardware; in the CPU-bound software sandbox, staying under 25.0 ms guarantees no runaway physics stalling.
