extends SceneTree
## Contract test for the module text table (game/data/ui_texts.gd): every key the modules
## look up exists, every key in the table is used under res://modules/, and no text is empty.
const UI_TEXT = preload("res://data/ui_texts.gd")
const MODULES_ROOT := "res://modules"
var failures := 0

func check(label: String, ok: bool) -> void:
	print("UI_TEXTS ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _gd_files(path: String) -> Array:
	var files: Array = []
	var dir := DirAccess.open(path)
	if dir == null: return files
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				files.append_array(_gd_files(path.path_join(entry)))
		elif entry.ends_with(".gd"):
			files.append(path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	return files

func _initialize() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	var files := _gd_files(MODULES_ROOT)
	check("module scripts found %s" % [files], files.size() > 0)
	var used: Dictionary = {}
	var pattern := RegEx.create_from_string('UI_TEXT\\.t\\("([a-z0-9_]+)"\\)')
	for path in files:
		var source := FileAccess.get_file_as_string(path)
		for m in pattern.search_all(source): used[m.get_string(1)] = true
	check("modules look texts up through the table", used.size() >= 1)
	var missing: Array = used.keys().filter(func(k): return not UI_TEXT.TEXTS.has(k))
	check("every key the modules use resolves %s" % [missing], missing.is_empty())
	var unused: Array = UI_TEXT.keys().filter(func(k): return not used.has(k))
	check("every table key is used by the modules %s" % [unused], unused.is_empty())
	var empty: Array = UI_TEXT.keys().filter(func(k): return not (UI_TEXT.TEXTS[k] is String) or String(UI_TEXT.TEXTS[k]).is_empty())
	check("no text is empty %s" % [empty], empty.is_empty())
	check("lookup returns the stored text", UI_TEXT.t("sector_complete_title") == UI_TEXT.TEXTS["sector_complete_title"])
	print("UI_TEXTS SUMMARY failures=", failures)
	quit(1 if failures else 0)
