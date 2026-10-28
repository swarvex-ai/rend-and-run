extends SceneTree
func _initialize():call_deferred("run")
func run():
 var scene=load("res://main.tscn").instantiate()
 root.add_child(scene);current_scene=scene
 await create_timer(0.5).timeout
 var player=get_first_node_in_group("player")
 for e in get_nodes_in_group("enemies"):e.set_physics_process(false)
 var out=OS.get_environment("LAB_OUTPUT")
 for x in [0.0,16.0,38.0]:
  player.global_position=Vector3(x,0.1,0);player.velocity=Vector3.ZERO
  scene.get_node("Camera3D").global_position=player.global_position+scene.follow_offset
  await create_timer(0.3).timeout
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png(out+"/lab-%d.png"%int(x))
 print("LAB CAPTURE complete")
 quit()
