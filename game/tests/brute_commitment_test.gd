extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 print("V39-BRUTE %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func run()->void:
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(0.2).timeout
 var brute:Node
 for e in main.route.enemies:
  e.set_physics_process(false)
  if e.role==2:brute=e
 brute._enter(brute.WINDUP);brute._state_t=0.2
 brute.take_melee_hit(1,Vector3(7,1.8,0))
 check("early anticipation can be interrupted",brute._state==brute.RECOVERY and brute._hit_recovering and brute.hp==2)
 brute.hp=3;brute._stun=0;brute._enter(brute.WINDUP);brute._state_t=0.45
 brute.take_melee_hit(1,Vector3(7,1.8,0))
 check("committed cleaver keeps timing but takes full damage",brute._state==brute.WINDUP and is_equal_approx(brute._state_t,0.45) and brute.hp==2 and brute._stun==0 and not brute._hit_recovering)
 brute.receive_parry()
 check("parry still interrupts committed cleaver",brute._state==brute.RECOVERY and brute._stun>0)
 brute._stun=0;brute._enter(brute.SWING);brute.take_melee_hit(2,Vector3(7,1.8,0))
 check("lethal strike overrides commitment",brute._dead)
 print("V39-BRUTE SUMMARY failures=",failures);quit(1 if failures else 0)
