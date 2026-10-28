extends SceneTree
var failures := 0
var checks: Array = []
var main: Node3D
var boss: CharacterBody3D
func _initialize():call_deferred("run")
func check(label: String, ok: bool):
 checks.append({"label":label,"pass":ok})
 print("P28 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func capture(label: String):
 await process_frame
 if DisplayServer.get_name()=="headless":return
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("P28_OUTPUT")+"/"+label+".png")
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):
  push_error("Isolated /tmp/ user data required");quit(2);return
 root.size=Vector2i(960,540)
 main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 main.player.set_physics_process(false)
 for e in main.route.enemies:
  if e.encounter_id!="brute":e.set_physics_process(false);e.hide();e.collision_layer=0;e._dead=true
 boss=main.route.overseer
 boss.set_physics_process(false)
 var p=main.player
 p.global_position=Vector3(45,0,0)
 boss._physics_process(.1)
 check("dormant before arena",not boss.active and boss._state==boss.IDLE and boss.hp==12)
 boss.take_melee_hit(2,Vector3.ZERO)
 check("cannot damage dormant boss",boss.hp==12)
 p.global_position=Vector3(47.8,0,0);boss.get_node("VisualPivot").rotation.y=PI
 boss._physics_process(.01)
 check("interior activates with alert",boss.active and boss._state==boss.ALERT)
 main.route._process(0)
 check("owner activates boss HUD",main.route.overseer_hud.visible and main.route.overseer_hud._bar.value==12)
 check("HUD has real viewport bounds",main.route.overseer_hud.size==root.get_visible_rect().size and main.route.overseer_hud._panel.get_global_rect().position.y>0)
 boss._enter(boss.WINDUP)
 check("first high tell",not boss._committed_low and boss._attack_cue._kind=="high" and is_equal_approx(boss._windup_duration(),.8))
 boss._state_t=.4;boss._update_weapon_pose(0)
 main.get_node("Camera3D").global_position=Vector3(48.1,1.05,5.8)
 await capture("high")
 boss._enter(boss.RECOVERY);boss._hit_recovering=true;boss._state_t=.62;boss._stun=.3
 var before_repeat:int=boss.hp
 boss.take_melee_hit(1,Vector3.ZERO)
 check("repeat hit preserves elapsed recovery",is_equal_approx(boss._state_t,.62) and boss._state==boss.RECOVERY)
 check("repeat hit still deals full damage",boss.hp==before_repeat-1)
 check("follow-up preserves longer parry stun",is_equal_approx(boss._stun,.3))
 boss.hp=6
 check("damage does not change committed attack",boss.phase==1 and not boss._committed_low and is_equal_approx(boss._windup_duration(),.8))
 boss._enter(boss.RECOVERY)
 check("full punish window",is_equal_approx(boss._recovery_duration(),.9))
 boss._enter(boss.WINDUP)
 check("next tell latches phase two low",boss.phase==2 and boss._committed_low and boss._attack_cue._kind=="low" and boss.hp==6)
 main.route._process(0)
 check("HUD receives phase and damage",main.route.overseer_hud._phase_label.text=="Phase 2" and main.route.overseer_hud._bar.value==6)
 boss._state_t=.35;boss._update_weapon_pose(0)
 await capture("low")
 # Test actual hurt-volume routing in the real physics world.
 boss.global_position=Vector3(49,0,0);p.global_position=Vector3(48,0,0)
 boss._attack_front=-1;boss._committed_low=false
 p._iframes=0;p.crouching=true
 await physics_frame
 var before:int=p.hp
 boss._swing_hit=false;boss._try_swing_hit(p,-1,0)
 check("duck avoids high",p.hp==before and not boss._swing_hit)
 p.crouching=false;boss._swing_hit=false;boss._try_swing_hit(p,-1,0)
 check("standing takes one high hit",p.hp==before-1)
 p._iframes=0;boss._try_swing_hit(p,-1,0)
 check("one hit per swing",p.hp==before-1)
 boss._committed_low=true;p.global_position.y=.65;boss._swing_hit=false;p._iframes=0
 boss._try_swing_hit(p,-1,0)
 check("jump clears low sweep",p.hp==before-1 and not boss._swing_hit)
 p.global_position.y=0;p.crouching=true;boss._try_swing_hit(p,-1,0)
 check("low sweep catches duck",p.hp==before-2)
 boss._enter(boss.WINDUP);boss._state_t=.65;boss.receive_parry()
 check("parry cancels committed attack",boss._state==boss.RECOVERY and boss._stun>=.65 and boss._swing_hit)
 boss._update_weapon_pose(0)
 await capture("recovery")
 boss.hp=3;boss._stun=0;boss._severed=true
 p.global_position.x=45;boss._physics_process(.016)
 check("retreat resets without trapping",not boss.active and boss.hp==12 and boss.phase==1 and not boss._severed and boss.global_position.x==49)
 # Existing default role timings remain exactly unchanged.
 var regular=main.route.enemies[0]
 for role in 4:
  regular.role=role;regular._ranged_attack=false
  check("legacy role timing "+str(role),is_equal_approx(regular._windup_duration(),[.44,.4,.64,.44][role]) and is_equal_approx(regular._recovery_duration(),[.48,.38,.7,.48][role]))
 boss.reset_encounter();p.global_position=Vector3(47.7,0,0);p.crouching=false;p._iframes=99
 boss.set_physics_process(true)
 var seen: Dictionary={}
 for frame in 300:
  await physics_frame
  if boss._state==boss.SWING and boss._state_t>=.09:
   var kind: String="low-contact" if boss._committed_low else "high-contact"
   if not seen.has(kind):
    seen[kind]=true
    await capture(kind)
    if kind=="low-contact":
     var blade_height: float=boss._weapon_pivot.global_position.y-boss.global_position.y
     check("visible low blade matches hit band",blade_height>=.2 and blade_height<=.6 and absf(boss._weapon_pivot.global_basis.y.normalized().y)<.15)
 boss.set_physics_process(false)
 check("autonomous encounter uses both attacks",seen.size()==2)
 main.route.shards=7;main.route._last_grounded=Vector3(47,0,0)
 boss.active=true;boss.hp=2
 main.route.on_player_death()
 check("death resets boss and preserves reachable shard cache",boss.hp==12 and not boss.active and main.route.death_cache.amount()==7 and main.route.death_cache.position().x==47)
 p._dying=false;p.global_position=Vector3(47,0,0)
 check("cache can be reclaimed on next attempt",main.route.reclaim_shards() and main.route.shards==7)
 main.route.cleared=["first","duelist","guard"]
 boss.active=true;boss.hp=1
 boss.take_melee_hit(1,Vector3.ZERO)
 check("boss defeat opens exit and records legacy id",main.route.gate_open and "brute" in main.route.cleared)
 main.route._process(0)
 check("defeat hides boss HUD",not main.route.overseer_hud.visible)
 var hud=main.route.overseer_hud
 for viewport_size in [Vector2(640,360),Vector2(960,540)]:
  hud.size=viewport_size;hud.update_state(true,99,12,2)
  check("HUD bounds "+str(viewport_size),is_equal_approx(hud._panel.position.y,viewport_size.y-105) and hud._panel.size.x<=340 and hud._bar.value==12 and hud.mouse_filter==Control.MOUSE_FILTER_IGNORE)
 hud.update_state(false,0,12,1)
 await create_timer(3.0).timeout
 main.queue_free();await process_frame;await process_frame
 main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await process_frame
 check("completed legacy id prevents boss respawn",not is_instance_valid(main.route.overseer) and main.route.gate_open)
 main.queue_free();await process_frame;await process_frame
 var f=FileAccess.open(OS.get_environment("P28_OUTPUT")+"/integration.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"failures":failures,"checks":checks},"  "))
 print("P28 SUMMARY checks=",checks.size()," failures=",failures)
 quit(1 if failures else 0)
