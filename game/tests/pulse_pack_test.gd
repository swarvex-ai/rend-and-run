extends Node
var failures := 0
func check(label: String, ok: bool) -> void:
	print("V50 %s %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures += 1
func run() -> void:
	var main = get_parent()
	main.player.set_physics_process(false)
	var guard: Node3D
	for enemy in main.route.enemies:
		enemy.set_physics_process(false)
		if enemy.role == 3: guard = enemy
		else: check("melee role has no backpack", enemy._pulse_pack == null)
	await get_tree().create_timer(0.1).timeout
	var pack: Node3D = guard._pulse_pack
	check("guard owns imported pack", is_instance_valid(pack) and pack.get_child_count() == 1)
	var socket := pack.get_parent() as BoneAttachment3D
	check("chest socket", socket != null and socket.bone_name in ["mixamorig_Spine2", "Spine02"])
	var expected_local := pack.transform
	var before := pack.global_transform
	for sample in [["walk",0.25,0.0],["combat/hit_react",0.12,PI],["combat/slash_light",0.25,PI]]:
		guard.get_node("VisualPivot").rotation.y = sample[2]
		guard._anim.play(sample[0]);guard._anim.seek(sample[1],true);guard._anim.pause()
		await get_tree().process_frame;await get_tree().process_frame
		check("pose follows chest: " + sample[0], pack.global_transform.is_equal_approx(socket.global_transform * expected_local) and pack.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("turn and pose move accessory", not pack.global_transform.is_equal_approx(before))
	var death_pose := pack.global_transform
	guard._die(Vector3(4,4,0))
	var drops := get_tree().get_nodes_in_group("dropped_packs")
	check("death creates one physical accessory", drops.size() == 1 and drops[0] is RigidBody3D)
	check("drop preserves pose without teleport", pack.global_transform.is_equal_approx(death_pose))
	pack.drop(Vector3.ZERO)
	check("drop is idempotent", get_tree().get_nodes_in_group("dropped_packs").size() == 1)
	check("debris cannot damage or block actors", drops[0].collision_layer == 0 and drops[0].collision_mask == 1)
	guard.queue_free();await get_tree().process_frame
	check("debris survives owner deletion", is_instance_valid(pack))
	await get_tree().create_timer(5.1).timeout
	check("bounded debris cleanup", get_tree().get_nodes_in_group("dropped_packs").is_empty() and not is_instance_valid(pack))
	print("V50 RESULT failures=", failures)
	get_tree().quit(0 if failures == 0 else 1)
