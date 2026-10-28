extends SceneTree
## Fresh process per policy. Arranged setup only; input-only after START.
## H56 copy of lead outputs/mixed_encounter_probe/pair_probe.gd. ONLY additions:
## (1) 2.7s settlement observation after the last designated kill with inputs
## released, (2) honest settlement/outcome metadata and summed real foe HP.
## Policy decisions, setup positions and awareness assumptions are UNCHANGED.
var main:Node
var p:Node
var e:Node
var foes:Array=[]
var guard:Node
var events:Array=[]
var last_hp:int
var last_dash:=0.0
var dodges:=0
var taken:=0
var attack_cycle:=-1
var last_jump:=-1
var last_dodge:=-1
const SETTLE_S := 2.7 # H56: observation window after last designated kill
var snapshots:Array=[] # Stable value snapshots survive enemy queue_free().
func _initialize()->void:call_deferred("run")
func press(action:String,yes:bool)->void:
 if yes and not Input.is_action_pressed(action):Input.action_press(action)
 elif not yes and Input.is_action_pressed(action):Input.action_release(action)
func observe(t:float)->void:
 if p.hp<last_hp:
  taken+=1;events.append({"t":t,"event":"damage","amount":last_hp-p.hp})
 last_hp=p.hp
 if p._dash_left>0 and last_dash<=0:dodges+=1;events.append({"t":t,"event":"dodge"})
 last_dash=p._dash_left
 # Capture values while references are alive; never dereference a freed enemy.
 for i in foes.size():
  var foe=foes[i]
  if is_instance_valid(foe):
   snapshots[i]={"hp":maxi(0,foe.hp),"hits":foe.hits_taken,"shots":foe.shots_fired,"attacks":foe._attack_count,"x":foe.global_position.x}
func run()->void:
 var policy:=OS.get_environment("H49_POLICY")
 if policy not in ["mash","duck_jump","dodge"]:quit(2);return
 seed(49)
 main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(0.3).timeout
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 p=main.player
 for foe in main.route.enemies:
  foe.set_physics_process(false)
  if foe.role==1:e=foe
  elif foe.role==3:guard=foe
 if e==null:quit(2);return
 # Initial fixture only. Fresh profile preserves original HP and starter weapon.
 e.debug_reset_ai();e.global_position=Vector3(34.3,0.01,0);e.get_node("VisualPivot").rotation.y=PI
 guard.debug_reset_ai();guard.global_position=Vector3(37.8,0.01,0);guard.get_node("VisualPivot").rotation.y=PI
 foes=[e,guard]
 p.reset_state();p.global_position=Vector3(32,0.01,0);p.velocity=Vector3.ZERO
 await create_timer(0.75).timeout
 var initial_php:int=p.hp;var initial_ehp:int=e.hp;var initial_hits:int=e.hits_taken
 if initial_php!=5 or initial_ehp!=2 or p.weapon_id!="starter_sword":print("SETUP FAIL");quit(2);return
 # H56: sum the REAL designated foe HP/hits (was hardcoded "+2"/2-per-foe).
 var initial_foe_hp_total:=0;var initial_foe_hits_total:=0
 for foe in foes:
  initial_foe_hp_total+=foe.hp
  initial_foe_hits_total+=foe.hits_taken
  snapshots.append({"hp":maxi(0,foe.hp),"hits":foe.hits_taken,"shots":foe.shots_fired,"attacks":foe._attack_count,"x":foe.global_position.x})
 last_hp=p.hp
 if OS.get_environment("H49_AWARE")=="1":
  e._enter(e.CHASE);guard._enter(guard.CHASE) # Explicit alternate initial condition, before START.
 guard.set_physics_process(true)
 e.set_physics_process(true) # Last setup write. No actor/state writes after START.
 var started:=Time.get_ticks_msec();var elapsed:=0.0
 print("H49 START ",policy)
 while elapsed<12.0 and not p._dying:
  var living:Array=foes.filter(func(foe):return is_instance_valid(foe) and not foe._dead)
  if living.is_empty():break
  e=living[0]
  for foe in living:
   if absf(foe.global_position.x-p.global_position.x)<absf(e.global_position.x-p.global_position.x):e=foe
  elapsed=(Time.get_ticks_msec()-started)/1000.0
  observe(elapsed)
  var dir:float=signf(e.global_position.x-p.global_position.x)
  var distance:float=absf(e.global_position.x-p.global_position.x)
  var moving:bool=distance>1.1 or p.facing!=dir
  var attack:=false;var crouch:=false;var jump:=false;var dodge:=false
  if policy=="mash":attack=fmod(elapsed,0.16)<0.05
  else:
   var threat:bool=e._state in [e.WINDUP,e.SWING]
   if threat:
    if policy=="duck_jump":
     moving=false;crouch=not e._committed_low
     if e._committed_low and last_jump!=e._attack_count:
      jump=true;last_jump=e._attack_count
    elif e._state==e.WINDUP and e._state_t>=0.18 and last_dodge!=e._attack_count:
     moving=true;dodge=true;last_dodge=e._attack_count
   elif e._state==e.RECOVERY:attack=fmod(elapsed,0.16)<0.05
  press("move_right",moving and dir>0);press("move_left",moving and dir<0)
  press("crouch",crouch);press("jump",jump);press("dodge",dodge);press("attack",attack)
  await physics_frame
 observe(elapsed)
 for action in ["move_left","move_right","attack","jump","crouch","dodge"]:press(action,false)
 var wins:bool=foes.all(func(foe):return not is_instance_valid(foe) or foe._dead)
 var outcome_before:="win" if wins else "death" if p._dying else "timeout"
 # --- H56 settlement: only after ALL designated foes are dead. Inputs stay ---
 # released; simulation, player collision and in-flight projectiles stay alive.
 # No invulnerability, no teleport, no actor/state writes — observation only.
 var hp_at_kill:int=p.hp
 var events_at_kill:=events.size()
 var settlement_started:=Time.get_ticks_msec()
 var settlement_completed:=false
 if wins and not p._dying:
  while not p._dying and (Time.get_ticks_msec()-settlement_started)/1000.0<SETTLE_S:
   elapsed=(Time.get_ticks_msec()-started)/1000.0
   observe(elapsed)
   await physics_frame
  elapsed=(Time.get_ticks_msec()-started)/1000.0
  observe(elapsed)
  settlement_completed=(Time.get_ticks_msec()-settlement_started)/1000.0>=SETTLE_S and not p._dying
 var settlement_seconds:=maxf(0.0,(Time.get_ticks_msec()-settlement_started)/1000.0) if wins else 0.0
 var damage_after:Array=[]
 for i in range(events_at_kill,events.size()):
  if events[i].get("event")=="damage":damage_after.append(events[i])
 # Late projectile death inside the interval is a LOSS, never a settled win.
 var outcome:="loss" if p._dying else outcome_before
 var result={"aware_at_start":OS.get_environment("H49_AWARE")=="1","enemy_attacks_started":snapshots.reduce(func(acc,snapshot):return acc+snapshot.attacks,0),"policy":policy,"outcome":outcome,"outcome_before_settlement":outcome_before,"settlement_completed":settlement_completed,"settlement_seconds":settlement_seconds,"hp_at_kill":hp_at_kill,"hp_after_settlement":p.hp,"damage_events_after_kill":damage_after,"wall_seconds":elapsed,"player_start_hp":initial_php,"enemy_start_hp":initial_foe_hp_total,"player_end_hp":p.hp,"enemy_end_hp":snapshots.reduce(func(acc,snapshot):return acc+snapshot.hp,0),"hits_dealt":snapshots.reduce(func(acc,snapshot):return acc+snapshot.hits,0)-initial_foe_hits_total,"hits_taken":taken,"dodges_executed":dodges,"player_x":p.global_position.x,"enemy_x":snapshots[1].x,"guard_shots":snapshots[1].shots,"events":events,"errors":[],"limits":{"fixed_input_policies":["mash","duck_jump","dodge"],"n":1,"wall_seconds_is_wallclock_not_render_metric":true}}
 var f:=FileAccess.open(OS.get_environment("H49_OUTPUT")+"/"+policy+".json",FileAccess.WRITE)
 if not f:quit(2);return
 f.store_string(JSON.stringify(result,"  "));f.close();print(JSON.stringify(result));quit(0)
