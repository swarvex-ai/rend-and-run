extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 if not ok:failures+=1
 print("EXTENT ","PASS " if ok else "FAIL ",label)
func run():
 var world=Node3D.new();root.add_child(world)
 var gate=load("res://modules/combat/arena_gate.gd").new();gate.entry_x=69.65;world.add_child(gate)
 gate.update_encounter(70.0,false,true,true)
 check("shifted arena does not close through arriving player",not gate.locked)
 gate.update_encounter(70.5,false,true,true)
 check("shifted arena locks after clearance",gate.locked and is_equal_approx(gate.position.x,69.65))
 gate.update_encounter(71,false,false,false)
 check("boss defeat releases shifted barrier",not gate.locked)
 var route=load("res://modules/world/service_return.gd").new();route.lift_x=80;world.add_child(route);route.unlocked=true
 await physics_frame;await physics_frame
 check("lift interaction follows new endpoint",not route.prompt(Vector3(80,0,0)).is_empty() and route.prompt(Vector3(56,0,0)).is_empty())
 check("lift accepts upper return call",route.interact(Vector3(80,5,0)) and route.target_y==5)
 var q=PhysicsRayQueryParameters3D.create(Vector3(75,6,0),Vector3(75,4,0),1)
 var hit=world.get_world_3d().direct_space_state.intersect_ray(q)
 check("expanded return has real walkable floor",not hit.is_empty() and absf(hit.position.y-5)<.01)
 world.queue_free();await process_frame
 print("EXTENT SUMMARY failures=",failures);quit(1 if failures else 0)
