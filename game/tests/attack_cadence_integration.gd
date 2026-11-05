extends SceneTree
var failures:=0
var checks:Array=[]
var main:Node3D
var actors:Array=[]
func _initialize():call_deferred('run')
func check(label:String,ok:bool):
 checks.append({'label':label,'pass':ok});print('H65 ', 'PASS ' if ok else 'FAIL ',label)
 if not ok:failures+=1
func prepare():
 main.attack_cadence.reset()
 main.player.global_position=Vector3(31,0,0)
 main.player.hp=main.player.max_hp
 for i in actors.size():
  var e=actors[i];e._dead=false;e.role=0;e._stun=0;e._kb_timer=0;e._ranged_attack=false
  e.territory_min_x=-10000;e.velocity=Vector3.ZERO
  e.global_position=Vector3(29.1 if i==0 else 32.9 if i==1 else 33.0,0,0)
  e.get_node('VisualPivot').rotation.y=0 if i==0 else PI
  e._enter(e.CHASE)
func run():
 main=load('res://main.tscn').instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 main.set_physics_process(false)
 main.player.set_physics_process(false)
 for e in main.route.enemies:
  e.set_physics_process(false);e._dead=true;e.hide();e.collision_layer=0
 actors=[main.route.enemies[0],main.route.enemies[1],main.route.enemies[2]]
 for reverse in [false,true]:
  prepare()
  var a=actors[1] if reverse else actors[0]
  var b=actors[0] if reverse else actors[1]
  a.show();b.show();actors[2].hide()
  a._physics_process(1.0/60);b._physics_process(1.0/60)
  check('first onset immediate '+str(reverse),a._state==a.WINDUP)
  check('same-tick second held '+str(reverse),b._state==b.CHASE)
  var onset_tick:=-1
  for tick in range(1,10):
   main._physics_process(1.0/60)
   a._physics_process(1.0/60);b._physics_process(1.0/60)
   if b._state==b.WINDUP and onset_tick<0:onset_tick=tick
   await process_frame
  check('second starts after 8 ticks '+str(reverse),onset_tick==8)
  main._physics_process(.13);actors[2]._physics_process(1.0/60)
  check('two concurrent maximum retained '+str(reverse),actors[2]._state==actors[2].CHASE)
  if DisplayServer.get_name()!='headless':
   main.get_node('Camera3D').global_position=Vector3(31,1.05,5.8)
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OS.get_environment("H65_OUTPUT")+'/opposed-'+str(reverse)+'.png')
 prepare()
 main.player.global_position=Vector3(43,0,0)
 var guard=actors[0];guard.role=3;guard.global_position=Vector3(39,0,0)
 await physics_frame
 guard._physics_process(1.0/60)
 check('cover blocks ranged eligibility',guard._state==guard.CHASE)
 check('blocked lane consumes no claim',main.attack_cadence.active_count()==0)
 main.player.global_position=Vector3(31,3,0)
 actors[1].global_position=Vector3(32.9,0,0);actors[1]._physics_process(1.0/60)
 check('height rejection consumes no claim',main.attack_cadence.active_count()==0)
 main.attack_cadence.try_claim(0)
 check('distant encounter independent',main.claim_enemy_attack(8))
 main.attack_cadence.reset();main.claim_enemy_attack(0)
 main.set_physics_process(true);paused=true
 await create_timer(.2,true,false,true).timeout
 check('scene pause freezes onset clock',main.attack_cadence.active_count()==1)
 paused=false
 # Prevent actors from automatic decisions; only clock is enabled.
 await create_timer(.16).timeout
 check('one scene clock expires lock',main.attack_cadence.active_count()==0)
 prepare();actors[2]._dead=true;actors[2].hide()
 main.player._iframes=99.0
 for e in [actors[0],actors[1]]:e.show();e.set_physics_process(true)
 var previous=[actors[0]._state,actors[1]._state]
 var onsets:Array=[]
 var times:Array=[]
 for tick in 180:
  await physics_frame
  for index in 2:
   var e=actors[index]
   if e._state==e.WINDUP and previous[index]!=e.WINDUP:
    onsets.append(index);times.append(main.attack_cadence._time)
   previous[index]=e._state
  if tick in [4,12,28] and DisplayServer.get_name()!='headless':
   await process_frame
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OS.get_environment("H65_OUTPUT")+'/motion-'+str(tick)+'.png')
 for e in actors:e.set_physics_process(false)
 var separated:=true
 for index in range(1,times.size()):
  if times[index]-times[index-1]<.119:separated=false
 check('live opposing actors keep attacking',onsets.size()>=4 and onsets.has(0) and onsets.has(1))
 check('live local onsets stay separated',separated)
 print('H65 live onset times=',times,' actors=',onsets)
 var replacement=load('res://main.tscn').instantiate()
 check('new scene owns empty independent clock',replacement.attack_cadence.active_count()==0)
 replacement.free()
 var output_dir=OS.get_environment("H65_OUTPUT")
 var result_path=output_dir+'/integration.json'
 var f=FileAccess.open(result_path,FileAccess.WRITE) if output_dir!='' else null
 if f==null:
  printerr('H65 ERROR cannot write result file: ',result_path,' (H65_OUTPUT=',output_dir,')')
  failures+=1
 else:
  f.store_string(JSON.stringify({'failures':failures,'checks':checks},'  '))
  f.close()
 await create_timer(.8).timeout
 main.queue_free();await process_frame;await process_frame
 print('H65 SUMMARY checks=',checks.size(),' failures=',failures)
 quit(1 if failures else 0)
