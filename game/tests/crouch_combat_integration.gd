extends SceneTree
var main:Node3D
var failures:=0
var checks:Array=[]
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 checks.append({"label":label,"pass":ok});print("CROUCH ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func shot(label:String):
 await process_frame
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png(OS.get_environment("CROUCH_OUTPUT")+"/"+label+".png")
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 root.size=Vector2i(960,540)
 main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 main.pause_controller.resume();main.set_process(false)
 var p=main.player
 p.equip_weapon("robot_arm")
 for e in main.route.enemies:e.set_physics_process(false);e.hide()
 p.global_position=Vector3(27,0,0);p.velocity=Vector3.ZERO;p.facing=1
 main.get_node("Camera3D").global_position=Vector3(27.4,1.0,4.2)
 await create_timer(.3).timeout
 await shot("standing")
 Input.action_press("crouch")
 await create_timer(.3).timeout
 check("grounded crouch",p.crouching and p.is_on_floor() and is_equal_approx(p.hurt_height(),1.05))
 await shot("crouch")
 for modifier in p._hero_skel.get_children():
  if modifier.get_script()==preload("res://crouch_pose.gd"):
   check("stance keeps foot IK targets",modifier.max_foot_error<.03)
 Input.action_press("move_right");await create_timer(.25).timeout
 check("crouch walk cadence follows movement",p._anim_state=="walk" and p._hero_anim.speed_scale>1.5)
 Input.action_press("attack");await create_timer(.06).timeout;Input.action_release("attack");Input.action_release("move_right")
 check("moving low cut resets locomotion cadence",p._crouch_attack and is_equal_approx(p._hero_anim.speed_scale,p.ATTACK_TEMPO))
 await create_timer(.8).timeout
 check("stopping restores normal idle cadence",p._anim_state=="idle" and is_equal_approx(p._hero_anim.speed_scale,1.0))
 var crate=preload("res://modules/loot/supply_crate.gd").new();crate.hit_points=1
 main.add_child(crate);crate.global_position=p.global_position+Vector3(1,0,0)
 Input.action_press("attack");await create_timer(.06).timeout;Input.action_release("attack")
 check("actual input starts crouched cut",p._attack_phase>0 and p._crouch_attack and p.crouching)
 var starter_crouch_dur:float=p._attack_dur
 await create_timer(.18).timeout
 await shot("cut1")
 Input.action_press("attack");await create_timer(.05).timeout;Input.action_release("attack")
 Input.action_release("crouch")
 await create_timer(.23).timeout
 check("combo stays low after crouch release",p._seq==3 and p.crouching and p._crouch_attack)
 await shot("cut2")
 await create_timer(.65).timeout
 check("stands only after finishing combo",p._attack_phase==0 and not p.crouching)
 check("low combo hits floor-level crate",crate.is_broken())
 # Low ceiling must prevent auto-standing, including after a crouched attack.
 var roof:=StaticBody3D.new();roof.collision_layer=1
 var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(3,.2,2);col.shape=shape;roof.add_child(col)
 Input.action_press("crouch");await create_timer(.2).timeout
 main.add_child(roof);roof.global_position=p.global_position+Vector3(0,1.3,0)
 await physics_frame;await physics_frame
 Input.action_press("attack");await create_timer(.06).timeout;Input.action_release("attack");Input.action_release("crouch")
 await create_timer(.7).timeout
 check("attack never forces standing through roof",p.crouching and p.hurt_height()<1.2)
 roof.queue_free();await create_timer(.2).timeout
 check("clearance permits standing",not p.crouching)
 p.equip_weapon("reinforced_arm")
 check("reinforced arm replaces robot arm exclusively",p._heavy_model.visible and not p._starter_model.visible and p._sword_model==p._heavy_model)
 var arm_mesh=p._heavy_model.find_child("weapon_arm_detached",true,false)
 var arm_aabb:AABB=arm_mesh.get_aabb() if arm_mesh is MeshInstance3D else AABB()
 var reach:float=arm_aabb.end.y*p._heavy_model.scale.y if arm_mesh is MeshInstance3D else 0.0
 check("authored reinforced arm matches contact endpoints",arm_mesh is MeshInstance3D and absf(reach-0.484)<.001 and arm_aabb.position.y<=.06 and arm_aabb.end.y>=.06)
 check("authored arm grip root stays at hand",p._heavy_model.get_parent() is BoneAttachment3D and p._heavy_model.position.is_zero_approx() and p._heavy_model.rotation.is_zero_approx())
 Input.action_press("crouch");await create_timer(.2).timeout
 Input.action_press("attack");await create_timer(.08).timeout;Input.action_release("attack")
 check("heavy arm also attacks crouched",p._attack_phase>0 and p.crouching and p._attack_dur>starter_crouch_dur)
 await create_timer(.8).timeout
 Input.action_release("crouch");await create_timer(.2).timeout
 p.equip_weapon("robot_arm");Input.action_press("attack");await create_timer(.05).timeout;Input.action_release("attack")
 check("robot arm restored exclusively",p._starter_model.visible and not p._heavy_model.visible and p._sword_model==p._starter_model)
 check("standing arm timing preserved",not p._crouch_attack and is_equal_approx(p._attack_dur,.59/p.ATTACK_TEMPO))
 var f=FileAccess.open(OS.get_environment("CROUCH_OUTPUT")+"/integration.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
 await create_timer(.8).timeout
 main.queue_free();await process_frame;await process_frame
 print("CROUCH SUMMARY checks=",checks.size()," failures=",failures)
 quit(1 if failures else 0)
