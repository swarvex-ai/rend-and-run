extends SceneTree
func _initialize():call_deferred("run")
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.2).timeout
 var fixture=load("res://tests/arm_contact_fixture.gd").new();main.add_child(fixture)
 var errors=await fixture.run()
 main.queue_free();await process_frame;await process_frame
 quit(1 if errors else 0)
