extends Node
## Arranged contact fixture: real hero clips and physics targets, no AI playtest.
class Target extends StaticBody3D:
 var hits := 0
 func take_melee_hit(_damage: int, _knockback: Vector3) -> void: hits += 1
var failures := 0
var report: Array = []
func check(label: String, ok: bool) -> void:
 print("ARMCONTACT %s %s" % ["PASS" if ok else "FAIL", label])
 if not ok: failures += 1
func target(pos: Vector3) -> Target:
 var t := Target.new();t.position=pos;t.collision_layer=2;t.collision_mask=0
 var c := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size=Vector3(0.16,0.7,0.5);c.shape=shape;t.add_child(c)
 var mesh := MeshInstance3D.new();var box := BoxMesh.new();box.size=shape.size;mesh.mesh=box
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color(0.8,0.15,0.1);mesh.material_override=mat;t.add_child(mesh)
 get_parent().add_child(t);return t
func run() -> int:
 var main=get_parent();var p=main.player
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 for e in main.route.enemies:e.set_physics_process(false);e.hide();e.collision_layer=0
 p.set_physics_process(false);p.global_position=Vector3(30,0,0)
 var near:=target(Vector3(30.8,0.85,0));var far:=target(Vector3(32.1,0.85,0))
 var back:=target(Vector3(28.7,0.85,0));var above:=target(Vector3(30.8,3.0,0))
 await get_tree().physics_frame
 for weapon in ["robot_arm","reinforced_arm"]:
  for direction in [1.0,-1.0]:
   p.facing=direction;p.pivot.rotation.y=0 if direction>0 else PI
   near.position.x=30+0.8*direction;far.position.x=30+2.1*direction;back.position.x=30-1.3*direction;above.position.x=near.position.x
   await get_tree().physics_frame
   for seq in [1,3]:
    for t in [near,far,back,above]:t.hits=0
    p.equip_weapon(weapon);p._start_attack(seq)
    p._hero_anim.stop();p._hero_anim.play("slash_light" if seq==1 else "slash_combo_2",0.0)
    p._hero_anim.advance(0);p._hero_anim.pause();p._blade_contact.clear()
    var first_hit:float=-1.0
    var speed:float=0.8 if weapon=="reinforced_arm" else 1.0
    var clip:String="slash_light" if seq==1 else "slash_combo_2"
    var end:float=0.59 if seq==1 else 0.50
    for i in range(int(ceil(end*120))+1):
     var time:float=minf(i/120.0,end)
     p._hero_anim.seek(time,true);await get_tree().process_frame
     p._attack_phase=2 if time>= (0.16 if seq==1 else 0.08) and time <= (0.41 if seq==1 else 0.32) else 1
     if p._attack_phase!=2:p._blade_contact.clear()
     p._check_hits(1.0/120.0)
     if near.hits>0 and first_hit<0:first_hit=time/speed
    var label:String="%s seq%d face%+.0f"%[weapon,seq,direction]
    check(label+" actual arm hits once",near.hits==1)
    check(label+" no distant/behind/overhead damage",far.hits==0 and back.hits==0 and above.hits==0)
    check(label+" contact only in active window",first_hit >= (0.16 if seq==1 else 0.08)/speed)
    report.append({"case":label,"first_hit_seconds":first_hit,"near":near.hits,"far":far.hits,"behind":back.hits,"above":above.hits})
 print("ARMCONTACT RESULT failures=",failures)
 return failures
