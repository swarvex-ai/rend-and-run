extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 if not ok:failures+=1
 print("WORLD ","PASS " if ok else "FAIL ",label)
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.2).timeout
 var r=main.route
 check("every authored encounter spawns",r.enemies.size()==r.MISSION.ENCOUNTERS.size())
 check("boss spawn and gate share new room",absf(r.overseer.position.x-73)<.1 and absf(r.arena_gate.position.x-69.65)<.01)
 r.overseer.reset_encounter()
 check("boss reset cannot teleport into old room",absf(r.overseer.position.x-73)<.1)
 check("return station reaches new exit",absf(r.service_return.lift.position.x-80)<.01)
 var gaps:=0
 for x in range(44,83,2):
  var q=PhysicsRayQueryParameters3D.create(Vector3(x,.1,0),Vector3(x,-1,0),1)
  if r.get_world_3d().direct_space_state.intersect_ray(q).is_empty():gaps+=1
 check("new rooms have continuous collision floor",gaps==0)
 var restored=load("res://lab_route.gd").new()
 restored._restore_progress({"version":12,"completed":true,"cleared":["first","duelist","guard","brute"],"shards":9,"economy_revision":1,"death_cache":{"amount":3,"position":[52,0,0]}})
 check("legacy completed run maps progress and cache",restored.MISSION.all_cleared(restored.cleared) and restored.shards==9 and restored.death_cache.position().x==76)
 restored.free()
 print("WORLD SUMMARY failures=",failures);quit(1 if failures else 0)
