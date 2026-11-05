#!/usr/bin/env bash
# Run the Rend&Run test suite listed in game/tests/manifest.txt.
#
#   tools/run_tests.sh                 headless + window + hook tests
#   tools/run_tests.sh --headless      only headless tests; every test runs without a display
#   tools/run_tests.sh --quarantine    additionally run quarantined tests (reported separately)
#   tools/run_tests.sh name ...        run only the named tests; any failure among them fails the run
#   tools/run_tests.sh --headless name run named tests (also quarantined ones) without a display
#
# Every test gets its own XDG_DATA_HOME/XDG_CONFIG_HOME under $RENDRUN_TEST_DIR
# (default /tmp/rendrun-tests), so real saves are never touched. Environment
# variables a script reads are derived from its source: *_OUTPUT -> per-test
# output directory, any other flag -> "1". Logs land next to the outputs.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GAME=$ROOT/game
MANIFEST=$GAME/tests/manifest.txt
OUT=${RENDRUN_TEST_DIR:-/tmp/rendrun-tests}
JOBS=${JOBS:-6}
TIMEOUT=${TIMEOUT:-240}
GODOT=${GODOT:-godot}
# Window tests open on this screen (Godot's index; 1 = the small side monitor here, so the
# main screen stays free). Missing screens fall back to the primary one.
TEST_SCREEN=${TEST_SCREEN:-1}

kinds="headless window hook"; only=(); FORCE_HEADLESS=0
for arg in "$@"; do
  case "$arg" in
    --headless) kinds="headless"; FORCE_HEADLESS=1 ;;
    --quarantine) kinds="$kinds quarantine" ;;
    -h|--help) sed -n 2,13p "$0"; exit 0 ;;
    *) only+=("$arg") ;;
  esac
done

rm -rf "$OUT"; mkdir -p "$OUT"
( cd "$GAME" && "$GODOT" --headless --import >"$OUT/_import.log" 2>&1 ) || { echo "import failed, see $OUT/_import.log"; exit 1; }

run_one() {  # kind name [flag] [VAR=value ...]
  local kind=$1 name=$2 flag="" dir="$OUT/$2" args=() overrides=()
  shift 2
  for token in "$@"; do
    if [[ "$token" == *=* ]]; then overrides+=("$token"); else flag=$token; fi
  done
  mkdir -p "$dir/data" "$dir/config" "$dir/out"
  local envs=(XDG_DATA_HOME="$dir/data" XDG_CONFIG_HOME="$dir/config")
  for v in $(grep -oE 'get_environment\("[A-Z0-9_]+"\)' "$GAME/tests/$name.gd" | sed -E 's/.*\("(.*)"\)/\1/' | sort -u); do
    case "$v" in
      *_OUTPUT) envs+=("$v=$dir/out") ;;
      *_CAPTURE) envs+=("$v=$dir/out/capture.png") ;;
      FACTORY_BASELINE_LENS|FINISHER|H49_POLICY) ;;
      *) envs+=("$v=1") ;;
    esac
  done
  envs+=("${overrides[@]}")
  if [ "$kind" = hook ] || { [ "$kind" = quarantine ] && [ -n "$flag" ]; }; then
    envs+=("$flag=1")
  else
    args=(-s "res://tests/$name.gd")
  fi
  # Headless runs use a fixed game clock: every frame advances exactly 1/60 s, so timers and
  # physics stay in step however loaded the machine is (and nothing waits for wall time).
  local mode=(--headless --fixed-fps 60)
  [ "$kind" = headless ] || [ "$FORCE_HEADLESS" = 1 ] || mode=(--windowed --resolution 960x540 --screen "$TEST_SCREEN")
  ( cd "$GAME" && env "${envs[@]}" timeout "$TIMEOUT" "$GODOT" "${mode[@]}" --audio-driver Dummy --path . "${args[@]}" >"$dir/test.log" 2>&1 )
  echo "$? $kind $name" >>"$OUT/_results.txt"
}
export -f run_one; export GAME OUT TIMEOUT GODOT FORCE_HEADLESS

selected() {  # kind name -> 0 if it should run
  if [ ${#only[@]} -gt 0 ]; then printf '%s\n' "${only[@]}" | grep -qx "$2"; return; fi
  [[ " $kinds " == *" $1 "* ]]
}

: >"$OUT/_results.txt"
# Headless tests run in parallel; anything that opens a window runs one at a time.
grep -v '^#' "$MANIFEST" | while read -r kind name rest; do
  # No trailing blank: xargs -L treats it as a line continuation.
  [ "$kind" = headless ] && selected "$kind" "$name" && echo "$kind $name${rest:+ $rest}"
done | xargs -r -P "$JOBS" -L1 bash -c 'run_one "$@"' _
grep -v '^#' "$MANIFEST" | while read -r kind name rest; do
  # shellcheck disable=SC2086 # rest holds the optional flag and VAR=value overrides
  [ "$kind" != headless ] && selected "$kind" "$name" && [[ "$kind" =~ ^(window|hook|quarantine)$ ]] && run_one "$kind" "$name" $rest
done

fail=0
while read -r code kind name; do
  if [ "$code" = 0 ]; then status=PASS; elif [ "$code" = 124 ]; then status=TIMEOUT; else status=FAIL; fi
  [ "$status" != PASS ] && [ "$kind" != quarantine ] && fail=1
  printf '%-7s %-10s %s\n' "$status" "$kind" "$name"
done < <(sort -k2,2 -k3 "$OUT/_results.txt") | tee "$OUT/_summary.txt" | grep -v '^PASS' || true
echo "---"
awk '{print $1, $2}' "$OUT/_summary.txt" | sort | uniq -c
echo "logs: $OUT/<test>/test.log"
# Named tests are what the caller asked for: a red quarantined test fails that run too.
if [ ${#only[@]} -gt 0 ]; then grep -q -v '^PASS' "$OUT/_summary.txt" && exit 1 || exit 0; fi
grep -q -v -E '^PASS|quarantine' "$OUT/_summary.txt" && exit 1 || exit 0
