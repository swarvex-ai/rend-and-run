extends SceneTree
# Integration contract: original rest rig + cap visibility + metre-scaled physics arm + no robot blood.
func _initialize():call_deferred("run")
func snap(label):
	if OS.get_environment("SEVER_OUTPUT").is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SEVER_OUTPUT")+"/"+label+".png")
func run():
	assert(OS.get_user_data_dir().begins_with("/tmp/"))
	root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	for enemy in main.route.enemies:enemy.set_physics_process(false)
	main.player.set_physics_process(false);main.player.global_position=Vector3(4,.05,0)
	var foe=main.route.enemies[0];foe.global_position=Vector3(6,.05,0);foe.get_node("VisualPivot").rotation.y=PI
	assert(foe._arm_mesh and foe._cap_mesh and foe._body_mesh)
	assert(foe._arm_mesh.visible and not foe._cap_mesh.visible)
	var baked_normal=foe._body_mesh.get_active_material(0).normal_texture
	assert(baked_normal!=null and foe._arm_mesh.get_active_material(0).normal_texture==baked_normal)
	assert(foe._cap_mesh.get_active_material(0).normal_texture==null)
	# 24 original bones, one exported severance socket, one runtime weapon socket.
	var bones:int=foe._skeleton.get_bone_count();assert(bones==26)
	assert(foe._skeleton.find_bone("sev_arm_left")>=0)
	var original=load("res://assets3d/characters/light_humanoid_v1/model.glb").instantiate();root.add_child(original)
	var old=original.find_child("Skeleton3D",true,false)
	for i in old.get_bone_count():
		var ni:int=foe._skeleton.find_bone(old.get_bone_name(i));assert(ni>=0)
		var a:Transform3D=old.get_bone_global_rest(i);var b:Transform3D=foe._skeleton.get_bone_global_rest(ni)
		# Blender/glTF float round-trip: 0.005 rig units = 0.05 mm in game.
		assert(a.origin.distance_to(b.origin)<.005)
		for axis in 3:assert(a.basis[axis].distance_to(b.basis[axis])<.0001)
	original.queue_free()
	foe._anim.play("combat/idle");foe._anim.advance(.25);foe._anim.pause()
	await create_timer(1.2).timeout;await snap("before")
	var fx=root.get_node("FX");var blood:int=fx.fx_stats.blood;var pools:int=fx.fx_stats.pool
	foe.hp=5;foe.take_melee_hit(1,Vector3(3,3,0))
	assert(foe._severed and not foe._arm_mesh.visible and foe._cap_mesh.visible)
	assert(foe._skeleton.get_bone_count()==bones)
	assert(fx.fx_stats.blood==blood and fx.fx_stats.pool==pools)
	var thrown=main.get_node("DetachedRobotArm");assert(thrown is RigidBody3D)
	assert(thrown.find_children("*","Skeleton3D",true,false).is_empty())
	var thrown_mesh=thrown.find_child("severed_robot_arm",true,false)
	assert(thrown_mesh!=null and thrown_mesh.get_active_material(0).normal_texture==baked_normal)
	assert(foe._body_mesh.get_active_material(0).normal_texture==baked_normal) # Hit flash retains finish.
	var col:CollisionShape3D=null
	for child in thrown.get_children():
		if child is CollisionShape3D:col=child
	assert(col and col.shape.size.length()>.3 and col.shape.size.length()<1.2)
	assert(col.position.length()>.1) # Collider must follow the arm, not sit at the shoulder pivot.
	assert(absf(thrown.global_basis.determinant()-1)<.001)
	foe._sever_arm();assert(main.find_children("DetachedRobotArm*","RigidBody3D",false,false).size()==1)
	await create_timer(.45).timeout;await snap("after")
	foe._anim.play("run");foe._anim.advance(.2);assert(not foe._arm_mesh.visible and foe._cap_mesh.visible)
	print("LIGHT SEVERANCE PASS bones=",bones," collider=",col.shape.size," robot blood delta=",fx.fx_stats.blood-blood)
	main.queue_free();for i in 8:await process_frame
	quit()
