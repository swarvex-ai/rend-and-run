extends SceneTree
## Contract test for the route text table (game/data/route_texts.gd): every key the route
## looks up exists, every key in the table is used, and no text is empty.
const TEXT = preload("res://data/route_texts.gd")
var failures := 0

func check(label: String, ok: bool) -> void:
	print("TEXTS ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	var source := FileAccess.get_file_as_string("res://lab_route.gd")
	var used: Dictionary = {}
	var pattern := RegEx.create_from_string('TEXT\\.t\\("([a-z0-9_]+)"\\)')
	for m in pattern.search_all(source): used[m.get_string(1)] = true
	check("route looks texts up through the table", used.size() >= 100)
	var missing: Array = used.keys().filter(func(k): return not TEXT.TEXTS.has(k))
	check("every key the route uses resolves %s" % [missing], missing.is_empty())
	var unused: Array = TEXT.keys().filter(func(k): return not used.has(k))
	check("every table key is used by the route %s" % [unused], unused.is_empty())
	var empty: Array = TEXT.keys().filter(func(k): return not (TEXT.TEXTS[k] is String) or String(TEXT.TEXTS[k]).is_empty())
	check("no text is empty %s" % [empty], empty.is_empty())
	check("lookup returns the stored text", TEXT.t("msg_blocked") == TEXT.TEXTS["msg_blocked"])
	check("formatting stays with the caller", TEXT.t("msg_shards_added") % [3, 9] == TEXT.TEXTS["msg_shards_added"] % [3, 9])
	print("TEXTS SUMMARY failures=", failures)
	quit(1 if failures else 0)
