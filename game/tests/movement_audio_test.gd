extends Node
var failures:=0
func check(label:String,ok:bool)->void:
 print("V33 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func steps()->int:return int(FX.audio_events.get("footstep_metal_a",0))+int(FX.audio_events.get("footstep_metal_b",0))
func run()->void:
 var clock=preload("res://modules/audio/foot_contact_clock.gd").new()
 check("clip entry does not invent contact",clock.advance("run",0.1).is_empty())
 check("left stance crossing",clock.advance("run",0.3)==[0])
 check("held phase emits nothing",clock.advance("run",0.3).is_empty())
 check("right stance crossing",clock.advance("run",0.8)==[1])
 check("wrap does not duplicate contact",clock.advance("run",0.1).is_empty())
 check("next loop emits next left",clock.advance("run",0.3)==[0])
 check("clip switch resets history",clock.advance("walk",0.9).is_empty())
 clock.reset();check("airborne reset discards history",clock.advance("walk",0.3).is_empty())
 var scene=get_tree().current_scene;var p=scene.player
 for e in scene.route.enemies:e.set_physics_process(false)
 await wait(0.3)
 # Run along the front of the floor strip, past the solid entry crate.
 p.global_position.z=1.0
 var n:=steps();await wait(0.3);check("idle is silent",steps()==n)
 Input.action_press("move_right");await wait(0.65);Input.action_release("move_right")
 check("running produces bounded foot contacts",steps()-n>=2 and steps()-n<=3)
 check("steps alternate distinct assets",FX.audio_events.get("footstep_metal_a",0)>0 and FX.audio_events.get("footstep_metal_b",0)>0)
 await wait(0.2);n=steps();await wait(0.3);check("stopping does not retrigger",steps()==n)
 p.global_position=Vector3(-3.4,0.03,0);p.velocity=Vector3.ZERO
 Input.action_press("move_left");await wait(0.5);n=steps();await wait(0.5);Input.action_release("move_left")
 check("pushing wall is silent",steps()==n)
 p.global_position=Vector3(0,0.03,0);p.velocity=Vector3.ZERO;await wait(0.2)
 var land:int=FX.audio_events.get("land_metal",0)
 Input.action_press("jump");Input.action_press("move_right");await wait(0.25);n=steps();await wait(0.1)
 check("airborne travel has no footsteps",not p.is_on_floor() and steps()==n)
 Input.action_release("jump");Input.action_release("move_right");await wait(1.0)
 check("jump landing plays exactly once",FX.audio_events.get("land_metal",0)==land+1)
 await wait(0.3);check("resting after landing remains silent",FX.audio_events.get("land_metal",0)==land+1)
 print("V33 SUMMARY failures=",failures)
 await wait(0.4);get_tree().quit(1 if failures else 0)
