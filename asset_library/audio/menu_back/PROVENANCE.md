# menu_back.wav — menu back click (2026-11-07)

| Field | Value |
|---|---|
| Source | Original synthesis, no samples or third-party material |
| Tool | Perl 5.40.1 (stdlib only: `strict`, `warnings`; 16-bit PCM WAV written with `pack`) |
| Author | swarvex contributor (task: Sound — menu_back.wav) |
| Licence | CC BY-SA 4.0 |
| Output | `game/audio/menu_back.wav` |
| SHA-256 | `8b32115d64fb6f0a282172f7b96c820a2b91b83e5a4308219935b4c783cb9d9b` |

## Design

A dry downward relay click for the menu "back" action, in the same contact family as
`block.wav` (confirm) and `radio_chirp.wav` (focus): shorter and quieter than confirm,
no reverb or tail. Deterministic seed `20261107`; regenerating produces the same file.

## Synthesis

- Dark broadband contact tick (one-pole low-passed noise, 1.5 ms decay).
- Descending relay resonance: 1800 → 480 Hz over 32 ms, 9 ms exponential decay.
- Low body: 200 → 90 Hz over 48 ms, 16 ms decay.
- Two softer relay-arm bounces at 12 ms and 23 ms (tick plus short 1050 → 340 Hz and
  780 → 290 Hz ring).
- DC removed, last 1.5 ms faded to zero, peak normalised to −16 dBFS.

## Processing / verification

Written directly as mono, 48 kHz, 16-bit PCM WAV; no further editing. Measured on the
final file:

- Duration 0.070000 s (3360 samples), first and last samples at signal (no silence padding)
- Mono, 48 kHz, 16-bit PCM
- Peak 5193 / 32768 = −16.00 dBFS, no clipping
- RMS −31.42 dBFS
