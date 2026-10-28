#!/usr/bin/env bash
# P04: Smoke-Test des exportierten Builds im echten Fenster (Desktop, KDE/Wayland).
set -u
export XDG_RUNTIME_DIR=/run/user/$(id -u)
BIN=${1:-$HOME/projects/nevs-game/builds/rendrun.x86_64}
timeout 8 "$BIN" >/tmp/rendrun_smoke.log 2>&1
code=$?
if [ "$code" -eq 124 ]; then echo SMOKE_OK_timeout_kept_running; else echo SMOKE_FAIL_exit_$code; fi
grep -ciE 'SCRIPT ERROR|Failed to (load|instantiate)' /tmp/rendrun_smoke.log || true
tail -3 /tmp/rendrun_smoke.log
