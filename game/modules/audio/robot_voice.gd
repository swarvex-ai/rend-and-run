extends Node
## Spoken lines (tools/generate_voice_lines.py): robots talk through a speaker on their body
## with a subtitle over the head; the plant's PA speaks through the hall with a subtitle in
## the message line. One shared pause keeps the squad from talking over each other.
## Autoload-free: lives in the route, group "robot_voice".

const LINES := {
	"no_way_out": "You can't get out of here, Rend.", "located": "Subject Rend located. Engaging.",
	"return_cell": "Return to your cell.", "stop_resisting": "Stop resisting.",
	"nowhere": "There is nowhere to run.", "converge": "All units, converge on my position.",
	"target": "Target acquired.", "flank": "Moving to flank.", "hold_line": "Hold the line.",
	"damage": "Damage critical.", "failing": "Systems failing.", "error": "Error.",
	"intruder": "Intruder detected.", "neutralized": "Subject neutralized.", "reload": "Reloading.",
}
const PA := {
	"escape": "Attention. A test subject has escaped from calibration. All units to sector one.",
	"lockdown": "Security alert. Maintenance sector is now in lockdown.",
	"intact": "Reminder. Escaped subjects are to be returned intact.",
	"assembly": "Warning. Unauthorized movement in the assembly hall.",
	"capture": "All production units, stand by for capture protocol.",
	"airlock": "The exit airlock is sealed. Overseer, intercept the subject.",
}
const PAUSE := 3.2            # s of quiet after any robot line
const TAUNTS := ["no_way_out", "located", "return_cell", "stop_resisting", "nowhere", "target"]

var route: Node
var _quiet := 0.0
var _said := {}               # robot -> lines it has said (no repeats per robot)
var lines_spoken := 0         # tests
var pa_spoken := 0

func _ready() -> void:
	add_to_group("robot_voice")

func _process(delta: float) -> void:
	_quiet = maxf(0.0, _quiet - delta)

## A robot says `key` (or a fresh taunt for "taunt"). Returns false when it stays silent.
func say(robot: Node3D, key: String, force := false) -> bool:
	if not is_instance_valid(robot) or (_quiet > 0.0 and not force):return false
	var said: Array = _said.get(robot, [])
	if key == "taunt":
		var fresh := TAUNTS.filter(func(k): return not k in said)
		if fresh.is_empty():return false
		key = fresh[randi() % fresh.size()]
	var path := "res://audio/voice/robot_%s.wav" % key
	if not ResourceLoader.exists(path):return false
	said.append(key);_said[robot] = said
	_quiet = PAUSE;lines_spoken += 1
	var speaker := AudioStreamPlayer3D.new();speaker.stream = load(path)
	speaker.unit_size = 6.0;speaker.max_db = 4.0;speaker.volume_db = 2.0
	robot.add_child(speaker);speaker.position.y = 1.6;speaker.play()
	speaker.finished.connect(speaker.queue_free)
	_subtitle(robot, LINES[key])
	return true

func _subtitle(robot: Node3D, text: String) -> void:
	var label := Label3D.new();label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test = true
	label.font_size = 30;label.pixel_size = 0.0042;label.outline_size = 8
	label.modulate = Color(0.85, 0.95, 1.0);label.outline_modulate = Color(0, 0, 0, 0.8)
	robot.add_child(label);label.position = Vector3(0, 2.2, 0)
	var tw := label.create_tween()
	tw.tween_interval(2.0);tw.tween_property(label, "modulate:a", 0.0, 0.4);tw.tween_callback(label.queue_free)

## Hall announcement with its subtitle in the message line.
func announce(key: String) -> void:
	var path := "res://audio/voice/pa_%s.wav" % key
	if not ResourceLoader.exists(path):return
	pa_spoken += 1
	var hall := AudioStreamPlayer.new();hall.stream = load(path);hall.volume_db = -4.0
	add_child(hall);hall.play();hall.finished.connect(hall.queue_free)
	if route and route.has_method("_message"):route._message("DURCHSAGE: " + PA[key], 5.5, 1)
