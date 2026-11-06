extends SceneTree
## Regression: the button that closes the workbench must not leak into gameplay.
## B closes the shop without starting a dodge/attack, the shop can be reopened at
## once, and closing with Esc does not swallow the next attack.

var main: Node3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(label: String, ok: bool) -> void:
	print("SHOPCLOSE ", "PASS " if ok else "FAIL ", label)
	if not ok:
		failures += 1

func key(code: int, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)
	await create_timer(.04, true, false, true).timeout

func pad(button: int, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)
	await create_timer(.04, true, false, true).timeout

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return
	root.size = Vector2i(960, 540)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(.3).timeout
	main.pause_controller.resume()
	for enemy in main.route.enemies:
		enemy.set_physics_process(false)
	var route = main.route
	var player = main.player
	var controller = main.pause_controller
	var shop = controller.shop
	# A weapon in hand, so an attack can start (same setup as arm_first_fight).
	route.equipment.grant("robot_arm")
	route.equipment.equip_weapon("robot_arm")
	player.equip_weapon("robot_arm")
	player.global_position = route.workbench_pos
	route.shards = 20

	# The workbench is up; B is bound to both close and dodge.
	shop.open_menu(route.workbench_state())
	await process_frame
	check("workbench opens", shop.visible)
	await pad(JOY_BUTTON_B, true)
	await pad(JOY_BUTTON_B, false)
	check("B closes workbench", not shop.visible)
	for i in 3:
		await physics_frame
	check("B does not dodge", player._dash_left <= 0)
	check("B does not attack", player._attack_phase == 0)
	route._use_workbench()
	await process_frame
	check("workbench opens again", paused and shop.visible)

	# Close with Esc and attack at once: the keyboard close must not swallow it.
	player.reset_state()
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	Input.action_press("attack")
	var attacked := false
	for i in 6:
		await physics_frame
		if player._attack_phase > 0:
			attacked = true
			break
	Input.action_release("attack")
	check("Esc close does not swallow the next attack", attacked)

	main.queue_free()
	await process_frame
	await process_frame
	print("SHOPCLOSE SUMMARY failures=", failures)
	quit(1 if failures else 0)
