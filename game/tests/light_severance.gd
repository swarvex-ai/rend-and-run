extends SceneTree
# Integration contract: original rest rig + cap visibility + metre-scaled physics arm + no robot blood.
var failures := 0
func check(label: String, ok: bool) -> void:
	print("LIGHT SEVERANCE ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize():call_deferred("run")
func snap(label):
	if OS.get_environment("SEVER_OUTPUT").is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SEVER_OUTPUT")+"/"+label+".png")
func run():
	var isolated := OS.get_user_data_dir().begins_with("/tmp/")
	check("isolated user data under /tmp", isolated)
	if not isolated: quit(1); return
	root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	for enemy in main.route.enemies:enemy.set_physics_process(false)
	main.player.set_physics_process(false);main.player.global_position=Vector3(4,.05,0)
	var foe=main.route.enemies[0];foe.global_position=Vector3(6,.05,0);foe.get_node("VisualPivot").rotation.y=PI
	var meshes_ok = foe._arm_mesh and foe._cap_mesh and foe._body_mesh
	check("severable arm, cap and body meshes exist", meshes_ok)
	if not meshes_ok: quit(1); return
	check("arm mesh visible and cap hidden", foe._arm_mesh.visible and not foe._cap_mesh.visible)
	var baked_normal=foe._body_mesh.get_active_material(0).normal_texture
	check("arm keeps the baked body normal map", baked_normal!=null and foe._arm_mesh.get_active_material(0).normal_texture==baked_normal)
	check("cap has no normal map", foe._cap_mesh.get_active_material(0).normal_texture==null)
	# 24 original bones, one exported severance socket, one runtime weapon socket.
	var bones:int=foe._skeleton.get_bone_count()
	check("skeleton has 26 bones", bones==26)
	check("severance socket exists", foe._skeleton.find_bone("sev_arm_left")>=0)
	var original=load("res://assets3d/characters/light_humanoid_v1/model.glb").instantiate();root.add_child(original)
	var old=original.find_child("Skeleton3D",true,false)
	for i in old.get_bone_count():
		var ni:int=foe._skeleton.find_bone(old.get_bone_name(i))
		check("original bone %d maps to the new rig" % i, ni>=0)
		if ni<0: quit(1); return
		var a:Transform3D=old.get_bone_global_rest(i);var b:Transform3D=foe._skeleton.get_bone_global_rest(ni)
		# Blender/glTF float round-trip: 0.005 rig units = 0.05 mm in game.
		check("bone %d rest origin matches" % i, a.origin.distance_to(b.origin)<.005)
		for axis in 3:check("bone %d rest basis axis %d matches" % [i, axis], a.basis[axis].distance_to(b.basis[axis])<.0001)
	original.queue_free()
	foe._anim.play("combat/idle");foe._anim.advance(.25);foe._anim.pause()
	await create_timer(1.2).timeout;await snap("before")
	var fx=root.get_node("FX");var blood:int=fx.fx_stats.blood;var pools:int=fx.fx_stats.pool
	foe.hp=5;foe.take_melee_hit(1,Vector3(3,3,0))
	check("severed state hides arm and shows cap", foe._severed and not foe._arm_mesh.visible and foe._cap_mesh.visible)
	check("severance keeps bone count", foe._skeleton.get_bone_count()==bones)
	check("no robot blood or pools", fx.fx_stats.blood==blood and fx.fx_stats.pool==pools)
	var thrown=main.get_node("DetachedRobotArm")
	var thrown_ok = thrown is RigidBody3D
	check("detached arm is a rigid body", thrown_ok)
	if not thrown_ok: quit(1); return
	check("detached arm has no skeleton", thrown.find_children("*","Skeleton3D",true,false).is_empty())
	var thrown_mesh=thrown.find_child("severed_robot_arm",true,false)
	check("detached mesh keeps baked normal", thrown_mesh!=null and thrown_mesh.get_active_material(0).normal_texture==baked_normal)
	check("hit flash keeps body finish", foe._body_mesh.get_active_material(0).normal_texture==baked_normal) # Hit flash retains finish.
	var col:CollisionShape3D=null
	for child in thrown.get_children():
		if child is CollisionShape3D:col=child
	var collider_ok = col and col.shape.size.length()>.3 and col.shape.size.length()<1.2
	check("collider is arm-sized", collider_ok)
	if not collider_ok: quit(1); return
	check("collider follows the arm", col.position.length()>.1) # Collider must follow the arm, not sit at the shoulder pivot.
	check("detached arm keeps uniform scale", absf(thrown.global_basis.determinant()-1)<.001)
	foe._sever_arm();check("second severance adds no duplicate arm", main.find_children("DetachedRobotArm*","RigidBody3D",false,false).size()==1)
	await create_timer(.45).timeout;await snap("after")
	foe._anim.play("run");foe._anim.advance(.2);check("severed look persists in run animation", not foe._arm_mesh.visible and foe._cap_mesh.visible)
	print("LIGHT SEVERANCE PASS bones=",bones," collider=",col.shape.size," robot blood delta=",fx.fx_stats.blood-blood)
	main.queue_free();for i in 8:await process_frame
	print("LIGHT SEVERANCE SUMMARY failures=", failures)
	quit(1 if failures else 0)
