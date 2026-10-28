extends Node
var failures := 0
func check(label: String, ok: bool) -> void:
 print("V47 %s %s" % ["PASS" if ok else "FAIL",label])
 if not ok:failures += 1
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func run() -> void:
 if get_tree().root.has_meta("v47_running"):queue_free();return
 get_tree().root.set_meta("v47_running",true)
 var main = get_parent();var route = main.route;var p = main.player
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 for e in route.enemies:e.set_physics_process(false)
 await wait(0.2)
 var can = route.coolant_canister;var guard = route.enemies[2];var brute = route.enemies[3];var far = route.enemies[0]
 guard.global_position = Vector3(38.5,0,0);guard._ranged_attack=true;guard._enter(guard.WINDUP);guard._state_t=0.6
 brute.global_position = Vector3(38.2,0,0);brute._enter(brute.WINDUP);brute._state_t=0.5
 far.global_position = Vector3(30,0,0);far._enter(far.WINDUP)
 route.enemies[1].global_position = Vector3(33,0,0)
 var hp_before: int = p.hp;var guard_hp: int = guard.hp;var brute_hp: int = brute.hp;var money: int = route.shards
 p.global_position=Vector3(35.95,0.01,0);p.velocity=Vector3.ZERO;p.facing=1
 await wait(0.15);Input.action_press("attack");await wait(0.04);Input.action_release("attack")
 await wait(0.28)
 check("actual sword input breaks canister once",can.is_broken() and route.coolant_releases==1)
 check("ranged charge interrupted and marker cleared",guard._state==guard.RECOVERY and guard._stun>0 and not guard._attack_cue._pivot.visible)
 check("committed brute attack interrupted",brute._state==brute.RECOVERY and brute._stun>0)
 check("outside radius unchanged",far._state==far.WINDUP and far._stun==0)
 check("pressure causes no HP or currency change",p.hp==hp_before and guard.hp==guard_hp and brute.hp==brute_hp and route.shards==money)
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  get_viewport().get_texture().get_image().save_png(OS.get_environment("V47_OUTPUT")+"/coolant_release.png")
 can.take_melee_hit(5,Vector3.ZERO);route._on_coolant_broken("security_coolant",99,can.global_position)
 check("duplicate break cannot release twice",route.coolant_releases==1 and route.shards==money)
 await wait(0.5)
 check("pressure visual expires",not route.coolant_release.is_active())
 # Separate arranged terrain-boundary case, with the actual security cover.
 can.restore_broken(false);route.coolant_consumed=false;can.global_position.x=39.5
 guard.global_position=Vector3(41.5,0,0);guard._stun=0;guard._enter(guard.WINDUP)
 await get_tree().physics_frame
 can.take_melee_hit(1,Vector3.ZERO)
 check("real cover blocks pressure within radius",guard._state==guard.WINDUP and guard._stun==0)
 check("gate and encounter count unchanged",route.cleared.is_empty() and not route.gate_open and route.enemies.size()==4)
 var saved = JSON.parse_string(FileAccess.get_file_as_string(route.SAVE_PATH))
 check("consumption saved without reward",saved is Dictionary and saved.get("coolant_consumed")==true and int(saved.shards)==money)
 reparent(get_tree().root);main.queue_free();await wait(0.1)
 var fresh=load("res://main.tscn").instantiate();get_tree().root.add_child(fresh);get_tree().current_scene=fresh
 await wait(0.2)
 var restored=fresh.route
 check("real scene reload restores broken shell",restored.coolant_consumed and restored.coolant_canister.is_broken() and restored.coolant_canister.get_node("Collision").disabled)
 check("reload emits no pressure or reward",restored.coolant_releases==0 and not restored.coolant_release.is_active() and restored.shards==money)
 print("V47 SUMMARY failures=",failures);get_tree().quit(1 if failures else 0)
