extends SceneTree
const TEXT = preload("res://data/route_texts.gd")
var failures:=0
var checks:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 checks+=1
 if not ok:failures+=1
 print("BRACE ","PASS " if ok else "FAIL ",label)
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout;main.pause_controller.resume();main.set_process(false)
 var p=main.player;var b=main.route.overseer
 p.set_physics_process(false);p.global_position=Vector3(47.8,0,0)
 for e in main.route.enemies:e.set_physics_process(false)
 b.active=true;b._enter(b.WINDUP);b._state_t=.1
 b.take_melee_hit(1,Vector3.ZERO)
 check("first early hit still interrupts",b._state==b.RECOVERY and b.hp==11)
 b.take_melee_hit(1,Vector3.ZERO);b._enter(b.WINDUP)
 check("two stagger hits arm next clearly signalled windup",b._braced_attack and b.get_node("RoleLabel").text=="STANDHAFT")
 check("original high low cue retained",b._attack_cue._kind in ["high","low"])
 var duration:float=b._windup_duration();b._state_t=.12
 b.take_melee_hit(2,Vector3.ZERO)
 check("braced early hit takes full damage",b.hp==8)
 check("braced tell not canceled or restarted",b._state==b.WINDUP and is_equal_approx(b._state_t,.12) and is_equal_approx(b._windup_duration(),duration))
 main.route._shown_combat_hints.erase("brace");main.route._combat_hint_cooldown=12
 main.route._offer_combat_hint()
 check("first brace explanation bypasses ordinary hint cooldown",main.route._shown_combat_hints.has("brace") and TEXT.t("msg_overseer_braced") in main.route.feedback.current_text())
 main.route._process(0)
 check("HUD names standhaft explicitly",main.route.overseer_hud._phase_label.text=="STANDHAFT")
 if DisplayServer.get_name()!="headless":
  root.size=Vector2i(960,540);main.get_node("Camera3D").global_position=Vector3(48.1,1.05,5.8)
  await process_frame;RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png(OS.get_environment("BRACE_OUTPUT")+"/braced-tell.png")
 b.receive_parry()
 check("parry cancels braced attack",b._state==b.RECOVERY and not b._braced_attack and b._brace_hits==0 and b._stun>=.65)
 b._enter(b.WINDUP);check("parry earns normal interruptible next tell",not b._braced_attack)
 b._brace_hits=2;b._enter(b.WINDUP);b._enter(b.SWING);b._enter(b.RECOVERY)
 check("completed swing restores vulnerable recovery",not b._braced_attack and b._brace_hits==0 and is_equal_approx(b._recovery_duration(),.9))
 b._brace_hits=2;b._enter(b.WINDUP);b.hp=1;b.take_melee_hit(1,Vector3.ZERO)
 check("brace cannot prevent death",b._dead and b.hp==0)
 print("BRACE SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
