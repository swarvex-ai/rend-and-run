extends SceneTree
## Regression: the servo shop must show a readable sentence for every failed
## action instead of an internal reason id such as "save_failed".
const TEXT := preload("res://data/route_texts.gd")

var main: Node3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(label: String, ok: bool) -> void:
	print("SHOPREASON ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return
	root.size = Vector2i(960, 540)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(.3).timeout
	var route = main.route
	for reason in ["not_at_workbench", "busy", "install", "save_failed", "unknown_module", "missing_base", "already_owned", "x_unknown"]:
		var text: String = route._shop_reason_text(reason)
		check(reason + " is readable", not text.is_empty() and not text.contains(reason) and not text.contains("_"))
	check("save_failed uses the saved-failure text", route._shop_reason_text("save_failed") == TEXT.t("shop_save_failed"))
	main.queue_free()
	await process_frame
	print("SHOPREASON SUMMARY failures=", failures)
	quit(1 if failures else 0)
