extends SceneTree
## ComicPlayer test: drives time with fixed delta steps; no wall clock.

var failures := 0

func _initialize():
	call_deferred("run")

func check(label: String, ok: bool, detail := "") -> void:
	print("COMIC_PLAYER %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:
		failures += 1

func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return

	root.size = Vector2i(1280, 720)

	var data = load("res://data/comic_intro.gd")
	check("comic_intro.gd loads", data != null)
	if data == null:
		print("COMIC_PLAYER SUMMARY failures=", failures)
		quit(1)
		return

	check("five panels", data.PANELS.size() == 5)
	var durations := [10.0, 9.0, 9.0, 8.0, 12.0]
	var paths_ok := true
	var captions_ok := true
	var captions := [
		"Rend spends his nights teaching machines to move.",
		"Every screen turns red.",
		"They were built to serve. Tonight they move like hunters.",
		"Everything goes dark.",
		"Rend wakes where the machines are born.",
	]
	for i in 5:
		var panel: Dictionary = data.PANELS[i]
		if panel["duration_s"] != durations[i]:
			paths_ok = false
		if panel["art"] != "res://assets/comic/intro_panel_%02d_art.png" % [i + 1]:
			paths_ok = false
		if panel["caption"] != captions[i]:
			captions_ok = false
	check("durations 10/9/9/8/12 and art paths", paths_ok)
	check("total duration 48 s", data.total_duration() == 48.0)
	check("captions word-for-word from script", captions_ok)
	check("panel 5 pa line", data.PANELS[4]["pa"] == "Unregistered intruder on the factory floor. Security units dispatched.")
	var all_non_empty := true
	for panel in data.PANELS:
		if panel["caption"] == "":
			all_non_empty = false
	check("every caption non-empty", all_non_empty)

	var player_res = load("res://modules/ui/comic_player.gd")
	check("comic_player.gd loads", player_res != null)
	if player_res == null:
		print("COMIC_PLAYER SUMMARY failures=", failures)
		quit(1)
		return

	var player = ComicPlayer.new()
	root.add_child(player)

	check("panel -1 before start", player.current_panel() == -1)
	check("skippable defaults to false", player.skippable == false)

	player.start()
	player.set_process(false)
	await process_frame
	check("panel 0 after start", player.current_panel() == 0)

	# missing art panel shows a placeholder plate without errors
	var missing_art := player._art.texture == null
	var plate_caption := false
	for child in player._captions.get_children():
		if child is PanelContainer:
			for grand in child.get_children():
				if grand is Label and grand.name == "CaptionLabel" and grand.text == captions[0]:
					plate_caption = true
	check("missing art shows placeholder plate with caption", missing_art and plate_caption)

	# drive time with fixed 1 s delta; panel boundaries at 10, 19, 28, 36, 48
	var boundaries := [10.0, 19.0, 28.0, 36.0, 48.0]
	var finished := {"count": 0}
	player.finished.connect(func(): finished["count"] += 1)

	var input_checked := false
	for s in range(1, 49):
		player._process(1.0)
		var crossed := 0
		for b in boundaries:
			if float(s) >= b:
				crossed += 1
		var expected := crossed
		if expected > 4:
			expected = 4
		check("panel at t=%d s" % s, player.current_panel() == expected, "%d" % player.current_panel())
		if s < 48:
			check("finished not yet at t=%d s" % s, finished["count"] == 0)
		if s == 20 and not input_checked:
			input_checked = true
			_dismiss_input(player)
			check("input ignored when not skippable", player.current_panel() == expected and finished["count"] == 0)
	check("finished exactly once after 48 s", finished["count"] == 1)

	# captions on panel 5 must stay inside the frame with a 48 px margin
	await process_frame
	await process_frame
	check("captions inside frame margin on panel 5", _captions_inside_margin(player))

	# skippable: Enter skips to the end and emits finished once
	var b = ComicPlayer.new()
	root.add_child(b)
	b.start()
	b.set_process(false)
	await process_frame
	b.skippable = true
	var b_finished := {"count": 0}
	b.finished.connect(func(): b_finished["count"] += 1)
	var ev := InputEventKey.new()
	ev.keycode = KEY_ENTER
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	check("skippable Enter finishes once", b_finished["count"] == 1)
	check("skippable Enter lands on last panel", b.current_panel() == 4)
	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_ENTER
	ev2.pressed = true
	Input.parse_input_event(ev2)
	check("skippable Enter does not finish again", b_finished["count"] == 1)
	b.queue_free()

	# art present: an in-memory ImageTexture is shown instead of the placeholder plate
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(8):
			img.set_pixel(x, y, Color("CAD5CF"))
	var tex := ImageTexture.create_from_image(img)
	var p = ComicPlayer.new()
	root.add_child(p)
	p.start()
	p.set_process(false)
	await process_frame
	var had_placeholder := p._art.texture == null
	p._art.texture = tex
	var art_present := p._art.texture != null
	check("art shown when art exists", had_placeholder and art_present)
	p.queue_free()

	player.queue_free()

	print("COMIC_PLAYER SUMMARY failures=", failures)
	quit(1 if failures else 0)

func _dismiss_input(player: ComicPlayer) -> void:
	for k in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		var key := InputEventKey.new()
		key.keycode = k
		key.pressed = true
		Input.parse_input_event(key)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	Input.parse_input_event(pad)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(100.0, 100.0)
	Input.parse_input_event(click)

func _captions_inside_margin(player: ComicPlayer) -> bool:
	var frame := player.get_global_rect()
	var margin := 48.0
	var union := Rect2()
	var first := true
	for child in player._captions.get_children():
		var r: Rect2 = child.get_global_rect()
		if first:
			union = r
			first = false
		else:
			union = union.merge(r)
	if first:
		return false
	return (
		union.position.x >= frame.position.x + margin
		and union.position.x + union.size.x <= frame.position.x + frame.size.x - margin
		and union.position.y >= frame.position.y + margin
		and union.position.y + union.size.y <= frame.position.y + frame.size.y - margin
	)
