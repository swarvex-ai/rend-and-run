extends SceneTree
# E3.1 Pressure task (S16): a single-digit quick-maths problem under a visible countdown.
# Pure logic test for res://modules/world/pressure_task.gd (RefCounted, no scene, no UI).
# Covers: seeded determinism, operand/answer rules over 200 seeds, countdown timeout that
# emits failed exactly once, correct submit emitting solved once, wrong submit failing at
# once, and that submit/tick after the end change nothing. Countdown >= 10 s.
const TASK := preload("res://modules/world/pressure_task.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("PRESSURE %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok: failures += 1
# Rules of a well-formed problem (spec): shown operands are single digits 1-9, for "-" the
# result is never negative, for "*" the operands are 2-9, and the answer is 0..81.
func valid(t) -> bool:
	var parts: PackedStringArray = t.question.split(" ")
	if parts.size() != 3: return false
	var a := int(parts[0]); var op: String = parts[1]; var b := int(parts[2])
	var ok := false
	match op:
		"+": ok = a >= 1 and a <= 9 and b >= 1 and b <= 9 and t.answer == a + b
		"-": ok = a >= 1 and a <= 9 and b >= 1 and b <= 9 and a >= b and t.answer == a - b
		"*": ok = a >= 2 and a <= 9 and b >= 2 and b <= 9 and t.answer == a * b
	return ok and t.answer >= 0 and t.answer <= 81
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	check("countdown is at least 10 s", TASK.COUNTDOWN >= 10.0, "COUNTDOWN=%s" % TASK.COUNTDOWN)
	# --- determinism: the same seed builds the same problem ----------------------------
	var a = TASK.new(); a.start(12345)
	var b = TASK.new(); b.start(12345)
	check("same seed -> same question", a.question == b.question, "%s / %s" % [a.question, b.question])
	check("same seed -> same answer", a.answer == b.answer, "%d / %d" % [a.answer, b.answer])
	check("start puts it RUNNING", a.state == TASK.State.RUNNING)
	check("start loads the full countdown", is_equal_approx(a.time_left, TASK.COUNTDOWN))
	# --- every seed builds a legal problem ---------------------------------------------
	var all_valid := true; var first_bad := ""
	for s in 200:
		var t = TASK.new(); t.start(s)
		if not valid(t): all_valid = false; first_bad = "seed %d: %s = %d" % [s, t.question, t.answer]; break
	check("200 seeds satisfy the operand/answer rules", all_valid, first_bad)
	# --- countdown: fails exactly after COUNTDOWN seconds, emits failed once -----------
	var t1 = TASK.new(); var f1: Array[int] = []; var s1: Array[int] = []
	t1.failed.connect(func() -> void: f1.append(1))
	t1.solved.connect(func() -> void: s1.append(1))
	t1.start(7)
	t1.tick(TASK.COUNTDOWN - 0.5)
	check("not failed just before the countdown ends", t1.state == TASK.State.RUNNING and f1.is_empty())
	t1.tick(0.5)
	check("fails exactly after COUNTDOWN seconds of tick", t1.state == TASK.State.FAILED and is_zero_approx(t1.time_left))
	check("timeout emits failed exactly once", f1.size() == 1 and s1.is_empty())
	t1.tick(5.0); t1.submit(t1.answer)
	check("tick and submit after the end change nothing", t1.state == TASK.State.FAILED and f1.size() == 1 and s1.is_empty())
	# --- correct submit: solves once ---------------------------------------------------
	var t2 = TASK.new(); var f2: Array[int] = []; var s2: Array[int] = []
	t2.failed.connect(func() -> void: f2.append(1))
	t2.solved.connect(func() -> void: s2.append(1))
	t2.start(7)
	check("correct submit returns true", t2.submit(t2.answer))
	check("correct submit emits solved once", s2.size() == 1 and f2.is_empty() and t2.state == TASK.State.SOLVED)
	t2.tick(1.0)
	check("submit/tick after a solve change nothing", (not t2.submit(t2.answer)) and s2.size() == 1 and f2.is_empty() and t2.state == TASK.State.SOLVED)
	# --- wrong submit: fails at once ---------------------------------------------------
	var t3 = TASK.new(); var f3: Array[int] = []; var s3: Array[int] = []
	t3.failed.connect(func() -> void: f3.append(1))
	t3.solved.connect(func() -> void: s3.append(1))
	t3.start(7)
	check("wrong submit returns false", (not t3.submit(t3.answer + 1)))
	check("wrong submit fails at once, emits failed once", t3.state == TASK.State.FAILED and f3.size() == 1 and s3.is_empty())
	t3.submit(t3.answer)
	check("correct submit after a failure is ignored", (not t3.submit(t3.answer)) and f3.size() == 1 and s3.is_empty() and t3.state == TASK.State.FAILED)
	# --- ignored unless RUNNING (before any start) -------------------------------------
	var t4 = TASK.new(); var f4: Array[int] = []; var s4: Array[int] = []
	t4.failed.connect(func() -> void: f4.append(1))
	t4.solved.connect(func() -> void: s4.append(1))
	check("submit before start is ignored", (not t4.submit(0)) and t4.state == TASK.State.IDLE and f4.is_empty() and s4.is_empty())
	t4.tick(TASK.COUNTDOWN * 2.0)
	check("tick before start does nothing", t4.state == TASK.State.IDLE and f4.is_empty() and s4.is_empty())
	print("PRESSURE SUMMARY failures=", failures)
	quit(1 if failures else 0)
