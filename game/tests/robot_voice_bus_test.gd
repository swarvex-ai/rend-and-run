extends SceneTree
## Contract test for the robot voice audio route: robot lines and PA announcements
## play on the settings' "Voices volume" bus (Voice), not on Master.
var failures := 0

func check(label: String, ok: bool) -> void:
	print("ROBOT_VOICE_BUS ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	await process_frame
	var voice = load("res://modules/audio/robot_voice.gd").new()
	root.add_child(voice)
	var robot := Node3D.new()
	root.add_child(robot)

	check("the robot says its line", voice.say(robot, "error", true))
	var speakers: Array = robot.get_children().filter(func(c): return c is AudioStreamPlayer3D)
	check("the robot got a speaker", speakers.size() == 1)
	if speakers.size() == 1:
		check("the robot line plays on Voice", speakers[0].bus == "Voice")

	voice.announce("escape")
	var halls: Array = voice.get_children().filter(func(c): return c is AudioStreamPlayer)
	check("the PA got a player", halls.size() == 1)
	if halls.size() == 1:
		check("the announcement plays on Voice", halls[0].bus == "Voice")

	var voice_index := AudioServer.get_bus_index("Voice")
	check("the Voice bus exists", voice_index >= 0)
	if voice_index >= 0:
		check("the Voice bus sends to Master", AudioServer.get_bus_send(voice_index) == &"Master")
	print("ROBOT_VOICE_BUS SUMMARY failures=", failures)
	quit(1 if failures else 0)
