extends SceneTree
## Fresh process per policy. Arranged setup only; input-only after START.
var main:Node
var p:Node
var e:Node
var events:Array=[]
var last_hp:int
var last_dash:=0.0
var dodges:=0
var taken:=0
var attack_cycle:=-1
var last_jump:=-1
var last_dodge:=-1
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
 if e==null:quit(2);return
 # Initial fixture only. Fresh profile preserves original HP and starter weapon.
 e.debug_reset_ai();e.global_position=Vector3(34.3,0.01,0);e.get_node("VisualPivot").rotation.y=PI
 p.reset_state();p.global_position=Vector3(32,0.01,0);p.velocity=Vector3.ZERO
 await create_timer(0.75).timeout
 var initial_php:int=p.hp;var initial_ehp:int=e.hp;var initial_hits:int=e.hits_taken
 if initial_php!=5 or initial_ehp!=2 or p.weapon_id!="starter_sword":print("SETUP FAIL");quit(2);return
 last_hp=p.hp
 if OS.get_environment("H49_AWARE")=="1":e._enter(e.CHASE) # Explicit alternate initial condition, before START.
 e.set_physics_process(true) # Last setup write. No actor/state writes after START.
 var started:=Time.get_ticks_msec();var elapsed:=0.0
 print("H49 START ",policy)
 while elapsed<12.0 and not e._dead and not p._dying:
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
 var result={"aware_at_start":OS.get_environment("H49_AWARE")=="1","enemy_attacks_started":e._attack_count,"policy":policy,"outcome":"win" if e._dead else "death" if p._dying else "timeout","wall_seconds":elapsed,"player_start_hp":initial_php,"enemy_start_hp":initial_ehp,"player_end_hp":p.hp,"enemy_end_hp":e.hp,"hits_dealt":e.hits_taken-initial_hits,"hits_taken":taken,"dodges_executed":dodges,"player_x":p.global_position.x,"enemy_x":e.global_position.x,"events":events,"errors":[]}
 var f:=FileAccess.open(OS.get_environment("H49_OUTPUT")+"/"+policy+".json",FileAccess.WRITE)
 if not f:quit(2);return
 f.store_string(JSON.stringify(result,"  "));f.close();print(JSON.stringify(result));quit(0)
