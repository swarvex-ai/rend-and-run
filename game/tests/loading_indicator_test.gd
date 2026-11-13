extends SceneTree

var failures := 0

func _initialize():
	call_deferred("run")

func check(label: String, ok: bool, detail := "") -> void:
	print("LOADING_INDICATOR %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:
		failures += 1

func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return

	# d) key loading exists in ui_texts.gd
	var ui_texts_script = load("res://data/ui_texts.gd")
	var key_exists: bool = ui_texts_script.TEXTS.has("loading")
	var loading_val: String = ui_texts_script.TEXTS.get("loading", "")
	check("loading key exists in ui_texts", key_exists and loading_val == "LOADING")

	# Load loading_indicator script
	var indicator_res = load("res://modules/ui/loading_indicator.gd")
	check("loading_indicator script exists", indicator_res != null)

	if indicator_res == null:
		print("LOADING_INDICATOR SUMMARY failures=", failures)
		quit(1 if failures else 0)
		return

	# a) show_on adds a visible indicator with the text from UI_TEXT.t("loading")
	var host = Node.new()
	root.add_child(host)
	var indicator = indicator_res.show_on(host)
	check("show_on returns indicator node", indicator != null and is_instance_valid(indicator))
	check("indicator added to host", indicator.get_parent() == host)
	check("indicator process_mode is ALWAYS", indicator.process_mode == Node.PROCESS_MODE_ALWAYS)
	check("indicator is CanvasLayer with layer 100", indicator is CanvasLayer and (indicator as CanvasLayer).layer == 100)

	var color_rect: ColorRect = null
	var label: Label = null
	for child in indicator.get_children():
		if child is ColorRect:
			color_rect = child
		elif child is Label:
			label = child
	if color_rect == null or label == null:
		for node in indicator.find_children("*", "ColorRect", true, false):
			if color_rect == null: color_rect = node as ColorRect
		for node in indicator.find_children("*", "Label", true, false):
			if label == null: label = node as Label

	check("indicator has full-rect ColorRect with dark background", color_rect != null and color_rect.color.is_equal_approx(Color(0.035, 0.045, 0.06)))
	var expected_text: String = ui_texts_script.t("loading")
	check("indicator label has loading text", label != null and label.text.begins_with(expected_text))

	# b) hide_now() removes/hides it
	indicator.hide_now()
	await process_frame
	var hidden_or_freed: bool = not is_instance_valid(indicator) or not indicator.visible or indicator.get_parent() == null
	check("hide_now hides or removes indicator", hidden_or_freed)
	host.queue_free()

	# c) from the start scene, with the env flag unset, call start._enter_game()
	# and check that within 3 frames a node named like the indicator exists in the tree before the scene changes
	OS.set_environment("V12_TEST", "")
	OS.set_environment("V29_TEST", "")
	var start = load("res://start.tscn").instantiate()
	root.add_child(start)
	current_scene = start
	await process_frame

	start._enter_game()

	var indicator_found := false
	for frame in range(3):
		await process_frame
		for child in start.get_children():
			if child.get_script() == indicator_res or child.name.to_lower().contains("loading"):
				indicator_found = true
				break
		if not indicator_found:
			for node in root.find_children("*", "CanvasLayer", true, false):
				if node.get_script() == indicator_res or node.name.to_lower().contains("loading"):
					indicator_found = true
					break
		if indicator_found:
			break

	check("indicator exists within 3 frames of _enter_game", indicator_found)

	# Wait a bit for scene transition to settle
	await create_timer(0.5).timeout

	print("LOADING_INDICATOR SUMMARY failures=", failures)
	quit(1 if failures else 0)
