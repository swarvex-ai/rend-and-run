# QA rules

How Rend&Run rates bugs, when a test goes into quarantine and comes out again, and what a bug fix must prove. These rules apply to every contributor and to the lead. Test mechanics: `AGENTS.md` (Tests) and `docs/architecture.md` (Tests and the contract).

## Severity

| Level | Meaning | Examples | Response |
|---|---|---|---|
| **S1 critical** | The game cannot be played or data is lost. | crash or freeze on the route; save file destroyed or not loadable; Rend cannot leave a room; the test pipeline cannot run at all | the lead acts the same day; the revert comes first, the fix second; nothing else is merged on top |
| **S2 major** | A core rule of M1 is broken, but the game runs. | a robot hits without its tell; damage, shards or equipment are wrong; a checkpoint restores the wrong state; a menu cannot be left with the gamepad | task within 24 h, on the critical path, min trust 1 |
| **S3 minor** | Something works but is wrong or rough. | wrong sound or effect; a cue a little too short or too long; a German text left over; camera clips into a wall | normal task (level A or B) in the current milestone |
| **S4 cosmetic** | Hardly noticeable, no effect on play. | a floating prop; a texture seam; a typo in a comment or log | collected; a task when it fits into a batch |

The question that decides between two levels: does the player notice it during a normal run, and does it change what they can do? If both are yes, it is S2 or higher.

## Regression rule

- Every bug fix comes with a regression test that fails on the old code. The summary shows both runs: **red on `base_commit`**, **green with the patch**.
- A test that was only ever seen green does not count as a regression test; it may never trigger the bug.
- If the bug cannot be tested automatically (pure look or feel), the summary shows a before and after screenshot or clip under the same conditions, and the lead decides.

## Quarantine

A test is in quarantine when its manifest line starts with `quarantine`. The pipeline does not run it; `tools/run_tests.sh --quarantine` or a named run does.

**Entry.** Only the lead quarantines a test (the manifest is protected), and only for one of these reasons:
1. **Stale:** the game changed on purpose and the test still checks the old behaviour.
2. **Flaky:** the test changes its result without a code change (seen red and green on the same commit).
3. **Harness:** the test cannot run in the pipeline (crash without a display, missing output path, hang).

**On entry**, the lead does all of this in the same commit or the same session:
- writes the reason, the evidence (failing check or log line) and the date in `docs/test-triage.md`;
- creates a repair task with the failing check named, or records why the test is retired.

A failing test that points to a real game bug is **not** quarantined. It stays red, and the bug gets a task by severity.

**Exit.** The lead moves a test out of quarantine after a repair is accepted and the full suite (`JOBS=3 tools/run_tests.sh --headless`) is green twice in a row after the test's manifest line was changed from `quarantine` to `headless` or `hook` (`--headless` never runs `quarantine` lines; use `--quarantine` or a named run to see them). The move is noted in `docs/test-triage.md`.

**Maximum age.** No test stays in quarantine longer than its milestone. At the milestone review, the lead decides for each quarantined test: repaired, or retired. A retired test is deleted together with a note in `docs/test-triage.md` that says what it covered and why that no longer exists (candidate: `machinery_chamber_integration`, still in quarantine: nothing builds the chamber any more, decided at the milestone review).

## Flaky tests

- A flaky test is a defect in the test contract and gets fixed at once (LEAD.md 7.1).
- It is never a reason to reject a contribution. The swarvex test pipeline (not `run_tests.sh`) reruns a red suite once and runs a counter-check without the contribution. If the base is red too, the contribution goes to review.
- Usual causes here and their fixes:

| Cause | Fix |
|---|---|
| unseeded randomness (robot strike choice, spread) | `seed(<number>)` at the start of the test, before the scene is created |
| waiting on wall time | wait on game time (`create_timer`, physics frames); the runner uses a fixed clock |
| an `assert` in a SceneTree script (prints, but does not end) | a check that prints FAIL and calls `quit(1)` |
| unbounded waits | every loop and wait has a bound; long tests add a watchdog timer |
| leftovers from an earlier check (bolts, effects, timers) | clean up or wait until they are gone, with a bound |

## What a green pipeline means

The test pipeline runs `swarvex.yaml`: import, then `JOBS=3 ../tools/run_tests.sh --headless`, which covers all headless and hook tests. Window tests need a display and run only locally; `probe` and `fixture` lines are never run by the suite (probes are run by hand); for visual changes the summary adds a screenshot.
