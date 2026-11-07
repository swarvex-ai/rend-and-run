extends Node
var failures:=0
class Target extends Node3D:
 var calls:=0
 var last_damage:=0
 var last_origin:=Vector3.ZERO
 var last_source:Node
 func take_damage(amount:int,origin:Vector3,source:Node=null)->void:
  calls+=1;last_damage=amount;last_origin=origin;last_source=source
func check(label:String,ok:bool)->void:
 print("V49 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func run()->void:
 seed(1337)
 var main=get_parent();var route=main.route;var p=main.player;var guard=route.enemies[2]
 for e in route.enemies:e.set_physics_process(false)
 p.set_physics_process(false);p.global_position=Vector3(35,0.01,0);p.hp=5;p._iframes=0
 guard.global_position=Vector3(32,0.01,0);guard.territory_min_x=30.0;guard._attack_front=1;guard._aim_point=p.global_position+Vector3(0,1.2,0)
 await wait(0.15)
 guard._fire_energy(p);await wait(0.7)
 check("live shooter projectile still deals one damage",p.hp==4)
 p.hp=5;p._iframes=0;guard._aim_point=p.global_position+Vector3(0,1.2,0)
 guard._fire_energy(p)
 var bolt:Node
 for child in main.get_children():
  if child.get_script()==preload("res://modules/combat/energy_bolt.gd") and not child.is_queued_for_deletion():bolt=child
 var handler:Node=null
 if is_instance_valid(bolt):handler=bolt.get_node_or_null("Impact")
 check("actual fired bolt owns impact handler",is_instance_valid(handler) and handler.get_parent()==bolt and handler.get_meta("shooter") is WeakRef)
 var weak:WeakRef=weakref(guard);guard.queue_free();await wait(0.08)
 check("handler does not retain shooter",weak.get_ref()==null)
 await wait(0.7)
 check("flight still damages after shooter is freed",p.hp==4)
 check("resolved bolt and handler are freed",not is_instance_valid(bolt))
 var target:=Target.new();main.add_child(target);target.global_position=Vector3(32,1,0)
 var source:=Node.new();main.add_child(source)
 var container:=Node3D.new();main.add_child(container)
 var impact=preload("res://modules/combat/energy_impact.gd").new();impact.configure(source,29.5,Vector3.RIGHT,1);container.add_child(impact)
 impact.resolve(target,Vector3(32,1.2,0),Vector3.LEFT);impact.resolve(target,Vector3.ZERO,Vector3.ZERO)
 check("single hit retains damage and direction",target.calls==1 and target.last_damage==1 and target.last_origin.is_equal_approx(Vector3(31.7,1.2,0)))
 check("live attacker attribution preserved for parry",target.last_source==source)
 var protected:=Target.new();main.add_child(protected);protected.position.x=26
 var blocked:=Node3D.new();main.add_child(blocked)
 var boundary=preload("res://modules/combat/energy_impact.gd").new();boundary.configure(null,29.5,Vector3.RIGHT,1);blocked.add_child(boundary)
 boundary.resolve(protected,Vector3(26,1,0),Vector3.LEFT)
 check("checkpoint territory remains protected",protected.calls==0)
 await wait(0.05)
 check("boundary impact also cleans up",not is_instance_valid(blocked))
 print("V49 SUMMARY failures=",failures);get_tree().quit(1 if failures else 0)
