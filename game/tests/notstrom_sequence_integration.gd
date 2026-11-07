extends SceneTree
const UI_TEXT = preload("res://data/ui_texts.gd")
var failures:=0
var checks:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 checks+=1
 if not ok:failures+=1
 print("NOTSTROM ","PASS " if ok else "FAIL ",label)
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout;main.pause_controller.resume();main.set_process(false)
 var r=main.route;var p=main.player;r.set_process(false);p.set_physics_process(false)
 var guard:Node=null
 for e in r.enemies:
  if e.encounter_id=="guard":guard=e
  else:e.set_physics_process(false)
 p.global_position=Vector3(32,0.05,0)
 await create_timer(2).timeout
 check("pulse guard cannot shoot into duel approach",guard.shots_fired==0 and not guard._can_attack() and not guard._has_fire_lane(p))
 check("pulse guard stays in coolant section",guard.global_position.x>=36.9)
 p.global_position=Vector3(38.5,.05,0)
 check("entering second encounter permits guard counterplay",guard._can_attack() and guard._has_fire_lane(p))
 var layout=load("res://modules/world/notstrom_layout.gd")
 check("duplicate and foreign save entries cannot open exit",not layout.all_cleared(["first","first","guard","foreign"]))
 var saved={"version":12,"economy_revision":1,"cleared":["first","duelist","guard","brute","foreign","guard"],"completed":true}
 var restored=load("res://lab_route.gd").new();restored._restore_progress(saved)
 check("old completed save retains all cleared encounters",layout.all_cleared(restored.cleared) and restored.completed and restored.cleared.size()==layout.ENCOUNTERS.size())
 check("five mission sections distinguish supply and exit",layout.zone(28)==UI_TEXT.t("zone_supply") and layout.zone(73)==UI_TEXT.t("zone_airlock"))
 restored.free()
 print("NOTSTROM SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
