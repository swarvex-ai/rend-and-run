extends SceneTree
var main:Node3D
var failures:=0
var checks:Array=[]
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 checks.append({"label":label,"pass":ok});print("H69 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func key(code:int):
 var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=true
 Input.parse_input_event(e);await create_timer(.04,true,false,true).timeout
 e=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=false
 Input.parse_input_event(e);await create_timer(.04,true,false,true).timeout
func pad(button:int):
 var e:=InputEventJoypadButton.new();e.button_index=button;e.pressed=true
 Input.parse_input_event(e);await create_timer(.04,true,false,true).timeout
 e=InputEventJoypadButton.new();e.button_index=button;e.pressed=false
 Input.parse_input_event(e);await create_timer(.04,true,false,true).timeout
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 root.size=Vector2i(960,540)
 main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 main.pause_controller.resume()
 for e in main.route.enemies:e.set_physics_process(false)
 var route=main.route;var player=main.player;var controller=main.pause_controller;var shop=controller.shop
 player.global_position=route.workbench_pos;player.set_physics_process(false)
 route.shards=20
 route._use_workbench();await process_frame
 check("open pauses without buying",paused and shop.visible and route.shards==20 and not route.equipment.owns("vibroblade"))
 check("initial purchase focus",root.gui_get_focus_owner()==shop._vibro_action)
 check("viewport follows CanvasLayer",shop.size==Vector2(960,540))
 await pad(JOY_BUTTON_DPAD_DOWN)
 check("D-pad reaches close",root.gui_get_focus_owner()==shop._btn_close)
 await pad(JOY_BUTTON_DPAD_UP)
 check("D-pad skips disabled equipped item",root.gui_get_focus_owner()==shop._vibro_action)
 await key(KEY_ENTER)
 check("keyboard explicit purchase once",route.shards==8 and route.equipment.owns("vibroblade") and player.weapon_id=="starter_sword")
 route.apply_workbench_action("not-an-item")
 check("invalid id cannot spend",route.shards==8)
 await process_frame
 route.apply_workbench_action("vibroblade");route.apply_workbench_action("starter_sword")
 check("same-frame duplicate blocked",player.weapon_id=="vibroblade" and route.shards==8)
 await process_frame
 shop._starter_action.grab_focus();await pad(JOY_BUTTON_A)
 check("gamepad explicit equip starter",player.weapon_id=="starter_sword" and route.shards==8)
 player.set_physics_process(true)
 await pad(JOY_BUTTON_B)
 await physics_frame;await physics_frame
 check("closing B does not dodge or attack",player._dash_left<=0 and player._attack_phase==0)
 player.set_physics_process(false)
 check("B closes only shop",not paused and not shop.visible and not controller.menu.visible)
 check("no combat input leak",not Input.is_action_pressed("attack") and not Input.is_action_pressed("dodge"))
 route._use_workbench();await process_frame;await key(KEY_ESCAPE)
 check("Esc closes without pause stacking",not paused and not shop.visible and not controller.menu.visible)
 route._use_workbench();await process_frame;await pad(JOY_BUTTON_START)
 check("Start closes shop",not paused and not shop.visible)
 route.equipment.reset();route.shards=3
 route._use_workbench();await process_frame
 check("unaffordable disabled and shortage",shop._vibro_action.disabled and shop._shortage_label.text=="Es fehlen 9 Splitter")
 check("no available action focuses close",root.gui_get_focus_owner()==shop._btn_close)
 route.apply_workbench_action("vibroblade")
 check("owner rechecks funds",route.shards==3 and not route.equipment.owns("vibroblade"))
 controller.resume();await create_timer(.05,true,false,true).timeout;player._attack_phase=1;route._use_workbench()
 check("cannot open during attack",not shop.visible and not paused)
 player._attack_phase=0;player._dash_left=.1;route._use_workbench()
 check("cannot open during dodge",not shop.visible)
 player._dash_left=0
 player.global_position.x=35;route._use_workbench()
 check("cannot open away from workbench",not shop.visible)
 player.global_position=route.workbench_pos;route.shards=20;route._use_workbench();await process_frame
 # Save failure without touching personal data: block only isolated test path.
 var save_path:String=ProjectSettings.globalize_path(route.SAVE_PATH)
 if FileAccess.file_exists(save_path):DirAccess.remove_absolute(save_path)
 DirAccess.make_dir_absolute(save_path)
 route.apply_workbench_action("vibroblade")
 check("failed save is explicit without second spend",route.save_error and route.shards==8 and shop._feedback_label.text.contains("Speichern fehlgeschlagen"))
 for dims in [Vector2i(640,360),Vector2i(960,540)]:
  root.size=dims;await process_frame;await process_frame
  var bounds:=Rect2(Vector2.ZERO,Vector2(dims))
  var inside:=true
  for child in shop.find_children("*","Control",true,false):
   if child.is_visible_in_tree() and not bounds.encloses(child.get_global_rect()):inside=false
  check("layout bounds "+str(dims),inside and shop.size==Vector2(dims))
  if DisplayServer.get_name()!="headless":
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OS.get_environment("H69_OUTPUT")+"/shop-"+str(dims.x)+".png")
 DirAccess.remove_absolute(save_path);route._save_progress()
 controller.resume();await create_timer(.05,true,false,true).timeout
 main.queue_free();await process_frame;await process_frame
 main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await process_frame
 check("purchase survives reload",main.route.equipment.owns("vibroblade") and main.route.shards==8 and main.player.weapon_id=="starter_sword")
 check("reload not paused and menu hidden",not paused and not main.pause_controller.shop.visible)
 main.queue_free();await process_frame;await process_frame
 var f=FileAccess.open(OS.get_environment("H69_OUTPUT")+"/integration.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
 print("H69 SUMMARY checks=",checks.size()," failures=",failures)
 quit(1 if failures else 0)
