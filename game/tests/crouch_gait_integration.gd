extends SceneTree
var p
var feet:Dictionary={}
var knees:Dictionary={}
var failures:=0
func _initialize():call_deferred("run")
func cache_pose():
 for side in ["Left","Right"]:
  var idx=p._hero_skel.find_bone("mixamorig_"+side+"Foot")
  feet[side]=p._hero_skel.global_transform*p._hero_skel.get_bone_global_pose(idx).origin
  idx=p._hero_skel.find_bone("mixamorig_"+side+"Leg")
  knees[side]=p._hero_skel.global_transform*p._hero_skel.get_bone_global_pose(idx).origin
func check(label:String,ok:bool):
 print("GAIT ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout;main.pause_controller.resume();main.set_process(false)
 p=main.player;p._hero_skel.skeleton_updated.connect(cache_pose)
 for e in main.route.enemies:e.set_physics_process(false);e.hide();e.collision_layer=0
 p.global_position=Vector3(27,0,0);p.velocity=Vector3.ZERO
 await create_timer(.2).timeout
 Input.action_press("crouch");await create_timer(.2).timeout
 for direction in ["move_right","move_left"]:
  Input.action_press(direction);await create_timer(.25).timeout
  var lifts={"Left":0,"Right":0};var previous={"Left":false,"Right":false};var both_air:=0;var max_error:=0.0
  for i in 180:
   await physics_frame;await process_frame
   var airborne:=0
   for side in ["Left","Right"]:
    var lifted:bool=feet[side].y-p.global_position.y>.175
    if lifted and not previous[side]:lifts[side]+=1
    previous[side]=lifted
    if lifted:airborne+=1
   if airborne==2:both_air+=1
   max_error=maxf(max_error,p._crouch_modifier.max_foot_error)
  check(direction+" both feet repeatedly lift",lifts.Left>=3 and lifts.Right>=3)
  check(direction+" balanced step counts",absi(lifts.Left-lifts.Right)<=1)
  check(direction+" keeps a supporting foot",both_air==0)
  check(direction+" reachable leg targets",max_error<.03)
  check(direction+" deliberate crouch speed",absf(absf(p.velocity.x)-1.8)<.05)
  print("GAIT CYCLES ",direction," ",lifts," error ",max_error)
  Input.action_release(direction);await create_timer(.3).timeout
  check(direction+" stop returns to two equally bent knees",absf(knees.Left.y-knees.Right.y)<.025)
  check(direction+" neither knee kneels on floor",minf(knees.Left.y,knees.Right.y)-p.global_position.y>.3)
 Input.action_release("crouch");await create_timer(.2).timeout
 check("release returns to standing",not p.crouching and p._crouch_modifier.amount<.01)
 main.queue_free();await process_frame;quit(1 if failures else 0)
