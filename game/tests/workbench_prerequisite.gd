extends SceneTree
const UI_TEXT = preload("res://data/ui_texts.gd")
var failures := 0
func _initialize(): call_deferred("run")
func check(label: String, ok: bool) -> void:
	print("WORKBENCH PREREQUISITE ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func run():
	var shop=load("res://modules/ui/workbench_menu.gd").new();root.add_child(shop)
	await process_frame
	shop.open_menu({"shards":6,"owned":[],"equipped":""})
	check("vibro action locked while arm missing", shop._vibro_action.disabled)
	check("shortage label asks to salvage the start arm", shop._shortage_label.visible and shop._shortage_label.text.contains(UI_TEXT.t("workbench_need_arm")))
	shop.update_state({"shards":2,"owned":["robot_arm"],"equipped":"robot_arm"})
	check("missing shards keep vibro action locked", shop._vibro_action.disabled and shop._shortage_label.text==UI_TEXT.t("workbench_missing_shards") % 4)
	shop.update_state({"shards":6,"owned":["robot_arm"],"equipped":"robot_arm"})
	check("affordable upgrade enables vibro action", not shop._vibro_action.disabled and not shop._shortage_label.visible)
	shop.queue_free();await process_frame
	print("WORKBENCH PREREQUISITE PASS: missing arm, missing shards, affordable")
	print("WORKBENCH PREREQUISITE SUMMARY failures=", failures)
	quit(1 if failures else 0)
