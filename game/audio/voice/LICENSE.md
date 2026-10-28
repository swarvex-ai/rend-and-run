# Rend voice (pain, death)

Source: "Male Grunt/Yelling sounds" by HaelDB, https://opengameart.org/content/male-gruntyelling-sounds
License: CC0 (dual-listed CC0 / OGA-BY 3.0; used under CC0). Vocalist 3 of the pack only, so Rend keeps one voice.
Processing (Claude, 22.10.2026): silence trimmed, 30 ms fade-out, mono, loudness matched to -16 dB RMS, peak <= -1 dBFS.
Original file names: rend_hurt_light 3grunt1/3/4/5, 3yell3/4; rend_hurt_heavy 3yell5/7/8/11/12/14; rend_death 3yell1/2/9/10.

## Robot lines and PA announcements (robot_*.wav, pa_*.wav)

Synthesised locally with Piper (https://github.com/rhasspy/piper) by `tools/generate_voice_lines.py`.
Voices: `en_US-norman-medium` (robots) and `en_US-kristin-medium` (PA), both trained from scratch
on LibriVox recordings, dataset licence: public domain (model cards at
https://huggingface.co/rhasspy/piper-voices). Post-processing with ffmpeg (robot / hall speaker).
