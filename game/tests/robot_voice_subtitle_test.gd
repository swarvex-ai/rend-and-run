extends SceneTree
## Contract test for the "Subtitles" accessibility switch: with subtitles off, robot lines
## and PA announcements keep their audio but drop the on-screen text.
var failures := 0

class RouteStub extends Node:
	var calls: Array = []
	func _message(text: String, time: float, priority: int) -> void:
		calls.append([text, time, priority])

func check(label: String, ok: bool) -> void:
	print("ROBOT_VOICE_SUBTITLE ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	await process_frame
	var fx := root.get_node_or_null("FX")
	check("the FX autoload exists", fx != null)
	if fx == null: quit(1); return

	var voice = load("res://modules/audio/robot_voice.gd").new()
	root.add_child(voice)
	var route := RouteStub.new()
	root.add_child(route)
	voice.route = route
	var robot := Node3D.new()
	root.add_child(robot)
	var other_robot := Node3D.new()
	root.add_child(other_robot)

	fx.subtitles_enabled = true
	check("the robot says its line", voice.say(robot, "error", true))
	var labels: Array = robot.get_children().filter(func(c): return c is Label3D)
	check("subtitles on: the robot line has a subtitle", labels.size() == 1)
	if labels.size() == 1:
		check("subtitles on: the subtitle shows the line", labels[0].text == voice.LINES["error"])
	voice.announce("escape")
	check("subtitles on: the PA shows its message", route.calls.size() == 1)
	check("subtitles on: the PA got a player", voice.get_children().any(func(c): return c is AudioStreamPlayer))

	fx.subtitles_enabled = false
	check("the robot says its line", voice.say(other_robot, "error", true))
	var speakers: Array = other_robot.get_children().filter(func(c): return c is AudioStreamPlayer3D)
	check("subtitles off: the robot still gets a speaker", speakers.size() == 1)
	var no_labels: Array = other_robot.get_children().filter(func(c): return c is Label3D)
	check("subtitles off: the robot gets no subtitle", no_labels.is_empty())
	var halls_before: int = voice.get_children().filter(func(c): return c is AudioStreamPlayer).size()
	voice.announce("escape")
	check("subtitles off: the PA shows no message", route.calls.size() == 1)
	var halls_after: int = voice.get_children().filter(func(c): return c is AudioStreamPlayer).size()
	check("subtitles off: the PA still got a player", halls_after == halls_before + 1)

	fx.subtitles_enabled = true
	print("ROBOT_VOICE_SUBTITLE SUMMARY failures=", failures)
	quit(1 if failures else 0)
