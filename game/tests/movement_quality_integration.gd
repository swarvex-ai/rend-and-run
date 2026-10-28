extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func check(label: String, ok: bool):
 print("MOVEMENT ", "PASS " if ok else "FAIL ", label)
 if not ok: failures += 1
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
 var main = load("res://main.tscn").instantiate()
 root.add_child(main); current_scene = main
 await create_timer(.3).timeout
 main.pause_controller.resume(); main.set_process(false)
 for e in main.route.enemies: e.set_physics_process(false); e.hide()
 var p = main.player
 p.global_position = Vector3(27,0,0); p.velocity = Vector3.ZERO
 await create_timer(.3).timeout
 Input.action_press("move_right")
 await create_timer(.12).timeout
 check("full run responds within 120 ms", p.velocity.x > 7.0 and p._anim_state == "run")
 Input.action_release("move_right")
 await create_timer(.12).timeout
 check("release stops within 120 ms", absf(p.velocity.x) < .01 and p._anim_state == "idle")
 # Isolate animation selection with genuine grounded state retained.
 p.set_physics_process(false)
 p.velocity.x = 5.0; p._update_locomotion()
 for speed in [4.4,4.6,4.3,4.7]:
  p.velocity.x = speed; p._update_locomotion()
 check("stick jitter does not restart run", p._anim_state == "run")
 p.velocity.x = 3.9; p._update_locomotion()
 check("slowing down returns to walk", p._anim_state == "walk")
 for speed in [4.4,4.6,4.3,4.7]:
  p.velocity.x = speed; p._update_locomotion()
 check("stick jitter does not restart walk", p._anim_state == "walk")
 p.velocity = Vector3.ZERO; p._land_lock = .18; p.set_physics_process(true)
 Input.action_press("jump")
 await create_timer(.05).timeout
 check("jump interrupts landing pose immediately", p.velocity.y > 0 and p._land_lock == 0 and p._anim_state == "jump")
 Input.action_release("jump")
 quit(1 if failures else 0)
