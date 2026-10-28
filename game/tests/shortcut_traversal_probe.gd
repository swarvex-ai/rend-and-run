extends SceneTree
## Independent H16 route feasibility probe; worker module deliberately not loaded.
var failures:=0
func check(label: String,ok: bool) -> void:
	if not ok:failures+=1
	print("H16-ROUTE %s %s"%["PASS" if ok else "FAIL",label])
func wait(t: float) -> void:await create_timer(t).timeout
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if OS.get_environment("H16_ROUTE_PROBE")!="1":quit(2);return
	var scene=load("res://main.tscn").instantiate();root.add_child(scene);current_scene=scene
	await wait(0.25)
	var p=scene.player
	for e in scene.route.enemies:e.set_physics_process(false)
	var barrier:=StaticBody3D.new();var collider:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(0.25,2.8,2);collider.shape=box;collider.position.y=1.4
	barrier.add_child(collider);scene.add_child(barrier);barrier.position.x=16.5
	p.global_position=Vector3(15,0.03,0);p.velocity=Vector3.ZERO
	await wait(0.2);Input.action_press("move_right");await wait(0.5);Input.action_release("move_right")
	check("locked lower passage blocks actual movement",p.global_position.x<16.3)
	p.global_position=Vector3(8.5,0.03,0);p.velocity=Vector3.ZERO;await wait(0.2)
	for target in [11.0,14.0,18.0]:
		Input.action_press("jump");Input.action_press("move_right")
		for frame in 100:
			await physics_frame
			if p.global_position.x>=target-0.12:break
		Input.action_release("move_right");await wait(0.6)
		Input.action_release("jump");await wait(0.1)
		print("H16-ROUTE landing ",target," ",p.global_position)
	check("three real jumps bypass locked door",p.global_position.x>17.5 and p.global_position.y>2.3)
	Input.action_press("move_right")
	for frame in 100:
		await physics_frame
		if p.global_position.x>20.6:break
	Input.action_release("move_right");await wait(0.8)
	Input.action_press("move_left")
	for frame in 100:
		await physics_frame
		if p.global_position.x<17.5:break
	Input.action_release("move_left");await wait(0.1)
	check("can reach east latch at floor height",p.global_position.x>16.8 and p.global_position.x<18 and p.global_position.y<0.15)
	collider.set_deferred("disabled",true);await physics_frame
	Input.action_press("move_left");await wait(0.6);Input.action_release("move_left")
	check("open shortcut permits ground return",p.global_position.x<15.8 and p.global_position.y<0.15)
	print("H16-ROUTE SUMMARY failures=",failures)
	scene.queue_free();await wait(0.2);quit(1 if failures else 0)
