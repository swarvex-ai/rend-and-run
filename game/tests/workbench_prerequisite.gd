extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var shop=load("res://modules/ui/workbench_menu.gd").new();root.add_child(shop)
	await process_frame
	shop.open_menu({"shards":6,"owned":[],"equipped":""})
	assert(shop._vibro_action.disabled)
	assert(shop._shortage_label.visible and shop._shortage_label.text.contains("Start bergen"))
	shop.update_state({"shards":2,"owned":["robot_arm"],"equipped":"robot_arm"})
	assert(shop._vibro_action.disabled and shop._shortage_label.text=="Es fehlen 4 Splitter")
	shop.update_state({"shards":6,"owned":["robot_arm"],"equipped":"robot_arm"})
	assert(not shop._vibro_action.disabled and not shop._shortage_label.visible)
	shop.queue_free();await process_frame
	print("WORKBENCH PREREQUISITE PASS: missing arm, missing shards, affordable")
	quit()
