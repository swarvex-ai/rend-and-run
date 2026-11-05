extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 print("DETAIL ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 var r=main.route;var d=r.get_node("WorldServiceDetails")
 check("nine replacement vents",d.find_children("Vent*","Node3D",false,false).size()==9)
 # world_service_details.gd:8 builds 4 UpperTray and :9 builds 15 ServiceTray segments.
 var expected_trays:=4+15
 check("nineteen cable segments",d.find_children("*Tray*","Node3D",false,false).size()==expected_trays)
 check("one replacement frame",d.has_node("SecurityDoorFrame") and not r.has_node("DoorHeader"))
 check("no extra collision",d.find_children("*","CollisionObject3D",true,false).is_empty())
 check("no extra lights",d.find_children("*","Light3D",true,false).is_empty())
 var rear:=true
 for child in d.get_children():
  if child.name!="SecurityDoorFrame":rear=rear and child.position.z<=-1.6
 check("dressing stays behind movement plane",rear)
 var mesh_a=d.get_node("ServiceTray30").find_children("*","MeshInstance3D",true,false)[0]
 var mesh_b=d.get_node("ServiceTray33").find_children("*","MeshInstance3D",true,false)[0]
 check("segments share mesh resource",mesh_a.mesh==mesh_b.mesh)
 check("neighboring segments meet on 3m grid",is_equal_approx(d.get_node("ServiceTray33").position.x-d.get_node("ServiceTray30").position.x,3.0))
 var frame=d.get_node("SecurityDoorFrame");var frame_pos=frame.global_position
 check("door collider retained",r.gate is StaticBody3D and r.gate.get_node("Collision") is CollisionShape3D)
 main.pause_controller.resume()
 r._open_gate()
 await create_timer(.9).timeout
 check("frame stays fixed as door lifts",frame.global_position==frame_pos and r.gate.position.y>8.9)
 # Cast along actual travel plane through the opened doorway.
 var q=PhysicsRayQueryParameters3D.create(Vector3(52,.9,0),Vector3(54,.9,0),1)
 check("opened passage unobstructed",r.get_world_3d().direct_space_state.intersect_ray(q).is_empty())
 print("DETAIL SUMMARY failures=",failures)
 main.queue_free();await process_frame;quit(1 if failures else 0)
