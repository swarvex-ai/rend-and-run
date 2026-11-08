extends SceneTree
const TEXT = preload("res://data/route_texts.gd")
const UI_TEXT = preload("res://data/ui_texts.gd")
var failures:=0
var checks:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 checks+=1
 if not ok:failures+=1
 print("TEACH ","PASS " if ok else "FAIL ",label)
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout;main.pause_controller.resume();main.set_process(false)
 var r=main.route;var p=main.player;r.set_process(false);p.set_physics_process(false)
 for e in r.enemies:e.set_physics_process(false);e._enter(e.IDLE)
 var first=r.enemies[0];p.global_position=first.global_position-Vector3(1,0,0);first._enter(first.WINDUP)
 r.feedback.clear();r.feedback.offer("Speicherfehler",3,5)
 r._offer_combat_hint()
 check("suppressed first lesson is not consumed",not r._shown_combat_hints.has("0:high") and r._combat_hint_cooldown==0)
 r.feedback.clear();r._offer_combat_hint()
 check("opening raider teaches duck without unavailable parry",r._shown_combat_hints.has("0:high") and r.feedback.current_text()==UI_TEXT.t("hint_high_no_shield"))
 first._enter(first.IDLE)
 var boss=r.overseer;p.global_position=boss.global_position-Vector3(1,0,0)
 for low in [false,true]:
  r.feedback.clear();r._combat_hint_cooldown=0;boss._enter(boss.WINDUP);boss._committed_low=low
  r._offer_combat_hint()
  var expected:String=UI_TEXT.t("hint_overseer_low") if low else UI_TEXT.t("hint_overseer_high" if r.shield else "hint_overseer_high_no_shield")
  check("boss actual band lesson "+str(low),r.feedback.current_text()==expected)
 boss._brace_hits=2;boss._enter(boss.WINDUP);r.feedback.clear();r.feedback.offer("Speicherfehler",3,5)
 r._offer_combat_hint();check("blocked brace lesson retries later",not r._shown_combat_hints.has("brace"))
 r.feedback.clear();r._offer_combat_hint()
 check("brace retry is honest about missing shield",r._shown_combat_hints.has("brace") and TEXT.t("msg_overseer_braced") in r.feedback.current_text() and not TEXT.t("advice_parry_or_dodge") in r.feedback.current_text())
 print("TEACH SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
