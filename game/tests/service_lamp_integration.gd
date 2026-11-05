extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 print("LAMP ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func route_lamp_positions()->Array:
 var source:=FileAccess.get_file_as_string("res://lab_route.gd")
 var fixture:=source.find('fixture.name="ServiceLamp%d"')
 if fixture<0:return []
 var loop:=source.rfind("for x in [",fixture)
 if loop<0:return []
 loop+="for x in [".length()
 var end:=source.find("]",loop)
 if end<0:return []
 var positions:Array=[]
 for token in source.substr(loop,end-loop).split(","):
  positions.append(float(token.strip_edges()))
 return positions
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var expected_xs=route_lamp_positions()
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 var lamps=main.route.find_children("ServiceLamp*","Node3D",false,false)
 check("%d reusable fixtures"%expected_xs.size(),lamps.size()==expected_xs.size())
 var lamp_xs=lamps.map(func(lamp):return lamp.position.x);lamp_xs.sort()
 var sorted_expected_xs=expected_xs.duplicate();sorted_expected_xs.sort()
 check("fixtures sit at route positions",lamp_xs==sorted_expected_xs)
 var total_lights:=0
 var shared:Mesh
 var mesh_shared:=true
 var lens_materials:Array=[]
 for lamp in lamps:
  var lights=lamp.find_children("*","OmniLight3D",true,false);total_lights+=lights.size()
  check(str(lamp.name)+" one bounded shadowless light",lights.size()==1 and not lights[0].shadow_enabled and lights[0].omni_range<=7)
  check(str(lamp.name)+" visible height and no collision",is_equal_approx(lamp.position.y,3.2) and lamp.find_children("*","CollisionObject3D",true,false).is_empty())
  var mesh=lamp.find_children("*","MeshInstance3D",true,false)[0]
  if shared==null:shared=mesh.mesh
  else:mesh_shared=mesh_shared and shared==mesh.mesh
  for i in mesh.mesh.get_surface_count():
   var m=mesh.get_active_material(i)
   if m is StandardMaterial3D and m.emission_enabled:lens_materials.append(m)
 check("%d lights replace old fixtures"%expected_xs.size(),total_lights==expected_xs.size())
 check("shared geometry across instances",mesh_shared)
 check("independent emissive tints",lens_materials.size()==expected_xs.size() and lens_materials[0]!=lens_materials[1])
 check("no old emissive proxy fixtures",main.route.find_children("Fixture*","MeshInstance3D",false,false).is_empty())
 var counts=lamps.map(func(lamp):return lamp.find_children("*","",true,false).size())
 await create_timer(.2).timeout
 check("fixture population remains bounded",counts==lamps.map(func(lamp):return lamp.find_children("*","",true,false).size()))
 print("LAMP SUMMARY failures=",failures)
 main.queue_free();await process_frame;quit(1 if failures else 0)
