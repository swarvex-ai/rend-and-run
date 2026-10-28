extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 if not ok:failures+=1
 print("ART ","PASS " if ok else "FAIL ",label)
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.2).timeout;main.pause_controller.resume();main.set_process(false)
 var r=main.route;var p=main.player
 for e in r.enemies:e.set_physics_process(false)
 p.set_physics_process(false)
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 p._cancel_attack();p._hero_anim.play("idle")
 await create_timer(.3).timeout
 var decks=r.find_children("MissionDeckSkin","Node3D",true,false)
 var covers=r.find_children("FreightCoverSkin","Node3D",true,false)
 # Floating decks were removed after neVs' playtest; the two freight covers remain.
 check("no floating deck skins and two cover skins",decks.size()==0 and covers.size()==2)
 var colliders_ok:=true
 for skin in decks:
  var b=skin.get_parent();var size:Vector3=b.get_node("Collision").shape.size
  colliders_ok=colliders_ok and is_equal_approx(size.y,.18) and is_equal_approx(size.z,2.2) and not b.get_child(0).visible
 for skin in covers:
  var b=skin.get_parent();colliders_ok=colliders_ok and b.get_node("Collision").shape.size.is_equal_approx(Vector3(1,.9,.65))
 check("original collision dimensions retained",colliders_ok)
 if DisplayServer.get_name()!="headless":
  for at in [Vector3(38.5,2.2,0),Vector3(48,.05,0),Vector3(63.2,.05,0)]:
   var x:float=at.x
   p.global_position=at
   main.get_node("Camera3D").global_position=p.global_position+main.follow_offset
   await process_frame;RenderingServer.force_draw(false)
   check("review saved "+str(x),root.get_texture().get_image().save_png(OS.get_environment("ART_OUTPUT")+"/room-%d.png"%int(x))==OK)
 print("ART SUMMARY failures=",failures);quit(1 if failures else 0)
