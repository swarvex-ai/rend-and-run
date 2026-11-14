# 0007: Sound bible, variant 2

- Status: accepted · 14.11.2026 · decided by neVs (message 17)

## Decision

1. **Variant 2** is the sound bible: `docs/design/sound-bible.md` (a copy of `sound-bible-variant-2.md` with the corrections below). It is the gate document for audio tasks.
2. Open questions follow the recommendations: drone-only exploration music at 60–70 BPM; siren plus a 140 BPM danger layer; ambience continues in the death pause; one PA line at the start of the pressure countdown plus a 90 ms tick per second; PA and robot voices kept separate.
3. Correction (lead): the variant called all existing effects CC0. Only the ambience beds are CC0; combat sounds, siren and radio are own synthesis under CC BY-SA 4.0 (`CREDITS.md`).
4. The pillar "read before hit" needs an audible tell at least 500 ms before contact for every attack. Today melee robots are audible only 0.083 s before the hit and ranged robots at the shot (`docs/measurements/tell-durations.md`); this is the first audio work (code plus sounds).

## Consequences

- Audio asset and code tasks are cut against the event list; tasks follow in the plan (E12).
