extends SceneTree
var failures:=0
func check(label:String,ok:bool)->void:
 print("H54 INTEGRATION %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var scene=load("res://main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await process_frame
 var r=scene.route;r.set_process(false)
 for e in r.enemies:e.set_physics_process(false)
 r._message("Speichern fehlgeschlagen",5,3);r._guard_feedback("block")
 check("save warning survives block",r.toast=="Speichern fehlgeschlagen" and r.toast_time==5)
 r._on_supply_broken("entry_supply",3,Vector3.ZERO)
 check("supply reward cannot hide save warning",r.toast=="Speichern fehlgeschlagen" and r.shards==3)
 r.feedback.tick(5);r._message("hint",3,0);r._guard_feedback("parry")
 check("parry replaces routine hint",r.toast=="PARIERT — Gegenangriff!")
 r._message("routine hint",3,0)
 check("hint cannot replace combat feedback",r.toast=="PARIERT — Gegenangriff!")
 r._guard_feedback("break")
 check("latest combat outcome replaces old outcome",r.toast.begins_with("SCHILDBRUCH"))
 r.feedback.tick(1.3)
 check("discarded hints do not replay",r.feedback.current_text().is_empty())
 r._message("SEKTOR GESICHERT",12,3);r._guard_feedback("block")
 check("completion survives routine combat feedback",r.toast=="SEKTOR GESICHERT")
 print("H54 INTEGRATION failures=",failures);quit(1 if failures else 0)
