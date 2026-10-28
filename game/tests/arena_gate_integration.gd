extends SceneTree
var fails:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 print("ARENA ","PASS " if ok else "FAIL ",label)
 if not ok:fails+=1
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 root.size=Vector2i(960,540)
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 main.pause_controller.resume();main.set_process(false)
 var p=main.player;var route=main.route;var boss=route.overseer;var gate=route.arena_gate
 p.set_physics_process(false)
 for e in route.enemies:e.set_physics_process(false)
 p.global_position=Vector3(46.1,0,0);boss.active=true
 await physics_frame;await physics_frame
 check("entry stays clear until whole player crossed",not gate.locked and gate.body.collision_layer==0)
 p.global_position.x=46.6
 await physics_frame;await physics_frame
 check("active encounter locks entry",gate.locked and gate.body.visible)
 main.get_node("Camera3D").global_position=Vector3(48.2,1.6,7)
 await process_frame
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png(OS.get_environment("ARENA_OUTPUT")+"/closed.png")
 var query=PhysicsRayQueryParameters3D.create(Vector3(46.2,1,0),Vector3(45,1,0),1)
 check("gate physically blocks return",not main.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
 route.shards=7;route._last_grounded=Vector3(47,0,0);p._dying=true;route.on_player_death()
 await physics_frame;await physics_frame
 check("death opens entry and resets living boss",not gate.locked and not boss.active and boss.hp==12)
 check("death preserves reachable cache",route.death_cache.amount()==7 and route.death_cache.position().x==47)
 p._dying=false;p.global_position.x=47
 check("cache reclaim still works",route.reclaim_shards() and route.shards==7)
 boss.active=true
 await physics_frame;await physics_frame
 check("new attempt locks again",gate.locked)
 boss._dead=true
 await physics_frame;await physics_frame
 check("boss defeat releases entry",not gate.locked and gate.body.collision_layer==0)
 check("no invisible postfight barrier",main.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
 main.queue_free();await process_frame;await process_frame
 print("ARENA SUMMARY failures=",fails);quit(1 if fails else 0)
