#!/usr/bin/env python3
"""Synthesises the robots' spoken lines and the plant's PA announcements (English).

Voices: Piper (local neural TTS) with public-domain voices trained from scratch on LibriVox
recordings - en_US-norman-medium (robots) and en_US-kristin-medium (PA). Models are kept out of
git under asset_library/work/piper/. Robots get a machine treatment (slightly lowered pitch,
ring modulation, bit crush, metallic comb echo), the PA a band-limited hall speaker.

Usage: tools/.venv-tts/bin/python tools/generate_voice_lines.py
Output: game/audio/voice/robot_<key>.wav, game/audio/voice/pa_<key>.wav
"""
import os, subprocess, tempfile

ROOT = os.path.dirname(os.path.abspath(__file__))
PIPER = os.path.join(ROOT, ".venv-tts", "bin", "piper")
MODELS = os.path.join(ROOT, "..", "asset_library", "work", "piper")
OUT = os.path.join(ROOT, "..", "game", "audio", "voice")

ROBOT = {
    "no_way_out": "You can't get out of here, Rend.",
    "located": "Subject Rend located. Engaging.",
    "return_cell": "Return to your cell.",
    "stop_resisting": "Stop resisting.",
    "nowhere": "There is nowhere to run.",
    "converge": "All units, converge on my position.",
    "target": "Target acquired.",
    "flank": "Moving to flank.",
    "hold_line": "Hold the line.",
    "damage": "Damage critical.",
    "failing": "Systems failing.",
    "error": "Error.",
    "intruder": "Intruder detected.",
    "neutralized": "Subject neutralized.",
    "reload": "Reloading.",
}
PA = {
    "escape": "Attention. A test subject has escaped from calibration. All units to sector one.",
    "lockdown": "Security alert. Maintenance sector is now in lockdown.",
    "intact": "Reminder. Escaped subjects are to be returned intact.",
    "assembly": "Warning. Unauthorized movement in the assembly hall.",
    "capture": "All production units, stand by for capture protocol.",
    "airlock": "The exit airlock is sealed. Overseer, intercept the subject.",
}
ROBOT_FX = ("asetrate=22050*0.93,aresample=22050,highpass=f=170,lowpass=f=5200,"
            "aeval='val(0)*(0.55+0.45*sin(2*PI*58*t))':c=same,acrusher=bits=9:mix=0.3,"
            "aecho=0.6:0.5:6|11:0.35|0.22,volume=1.7,alimiter=limit=0.9")
PA_FX = ("highpass=f=340,lowpass=f=3600,acrusher=bits=12:mix=0.15,"
         "aecho=0.8:0.6:140|290:0.32|0.18,volume=1.5,alimiter=limit=0.9")

def render(model, text, fx, path):
    with tempfile.NamedTemporaryFile(suffix=".wav") as raw:
        subprocess.run([PIPER, "-m", os.path.join(MODELS, model), "-f", raw.name], input=text.encode(), check=True, capture_output=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw.name, "-af", fx, "-ar", "22050", "-ac", "1", path], check=True)
    print("wrote", os.path.relpath(path, ROOT + "/.."))

os.makedirs(OUT, exist_ok=True)
for key, text in ROBOT.items():
    render("en_US-norman-medium.onnx", text, ROBOT_FX, os.path.join(OUT, f"robot_{key}.wav"))
for key, text in PA.items():
    render("en_US-kristin-medium.onnx", text, PA_FX, os.path.join(OUT, f"pa_{key}.wav"))
