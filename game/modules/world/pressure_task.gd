class_name PressureTask
extends RefCounted
## Pressure task of S16: a single-digit quick-maths problem under a visible countdown.
## Pure logic behind the pressure-task door (E3.2 door, E3.3 route wiring read question,
## time_left and state and drive start/tick/submit). The problem is built from a seeded
## RandomNumberGenerator, so a given seed always yields the same question and answer.

const COUNTDOWN := 12.0  # seconds on the visible countdown (S16 requires >= 10)
const OPS := ["+", "-", "*"]

enum State {IDLE, RUNNING, SOLVED, FAILED}

signal solved
signal failed

var question: String = ""
var answer: int = 0
var time_left: float = 0.0
var state: int = State.IDLE

func start(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var op: String = str(OPS[rng.randi_range(0, OPS.size() - 1)])
	var a := _operand(rng, op)
	var b := _operand(rng, op)
	if op == "-" and b > a:  # shown operands stay single digits, result never negative
		var swap := a; a = b; b = swap
	answer = _apply(a, op, b)
	question = "%d %s %d" % [a, op, b]
	time_left = COUNTDOWN
	state = State.RUNNING

func tick(delta: float) -> void:
	if state != State.RUNNING: return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_fail()

func submit(value: int) -> bool:
	if state != State.RUNNING: return false
	if value == answer:
		state = State.SOLVED
		solved.emit()
		return true
	_fail()
	return false

func _operand(rng: RandomNumberGenerator, op: String) -> int:
	return rng.randi_range(2, 9) if op == "*" else rng.randi_range(1, 9)

func _apply(a: int, op: String, b: int) -> int:
	match op:
		"+": return a + b
		"-": return a - b
		"*": return a * b
	return 0

func _fail() -> void:
	state = State.FAILED
	failed.emit()
