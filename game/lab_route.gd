extends Node3D
## V12: compact authored route. Persistent exploration, not infinite arena waves.
const MISSION = preload("res://modules/world/notstrom_layout.gd")
const TEXT = preload("res://data/route_texts.gd")
const ROUTE = preload("res://data/route_layout.gd")
const SAVE_PATH := "user://rendrun_route_v12.json"
const COPPER := Color(0.65,0.30,0.12)
const TEAL := Color(0.12,0.72,0.78)
const LAMP_TINTS := {"teal": TEAL, "warm": Color(1.0,.72,.43), "cool": Color(.75,.80,1.0)}
var combat_hud: Control
var ammo_hud: Control
const GUN_BENCH_POS := ROUTE.GUN_BENCH_POS  # weapon bench: mods for the drawn gun, paid in shards
var gun_mods := {}                         # saved copy of player.gun_mods
var _bench_pick := 0                       # which mod the bench offers
var _bench_guard_was := false
var help_visible := false
var _hud_state: Dictionary = {}
var main: Node3D
var player: CharacterBody3D
var armor := false
var shield := false
var shield_display: Node3D
var shield_pos:=ROUTE.SHIELD_POS
var checkpoint := false
var relay_checkpoint := false
var relay_console:Node3D
const RELAY_CHECKPOINT_POS := ROUTE.RELAY_CHECKPOINT_POS
var checkpoint_console: Node3D
var completed := false
var cleared: Array=[]
var shards := 0
var death_cache = preload("res://modules/loot/death_cache.gd").new()
var _cache_marker: Node3D
var _last_grounded := Vector3.ZERO
var _economy_migrated:=false
var arm_pickup: Node3D
const ITEMS = preload("res://modules/equipment/item_catalog.gd")
var equipment=preload("res://modules/equipment/equipment_ledger.gd").new()
var servo_run=preload("res://modules/loot/servo_run_ledger.gd").new()
var servo_trial: Node
var _workbench_action_frame := -1
var workbench_pos:=ROUTE.WORKBENCH_POS
const ENTRY_WORKBENCH_POS := ROUTE.ENTRY_WORKBENCH_POS
const FIRST_SALVAGE_ID := "enemy_first"
var first_salvage_position := ROUTE.FIRST_SALVAGE_POS
var shortcut_open:=false
var power_sector:Node3D
var power_state:Dictionary={}
var shortcut: Node3D
var shortcut_pos:=ROUTE.SHORTCUT_POS
var broken_crates: Array=[]
var supply_crates: Array=[]
var pending_shards: Dictionary = {}
var shard_pickups: Dictionary = {}
const CRATE_POSITIONS := ROUTE.CRATE_POSITIONS
var enemies: Array=[]
var service_return: Node3D
var arena_gate: Node3D
var overseer: CharacterBody3D
var overseer_hud: Control
var armor_display: Node3D
var gate: StaticBody3D
var gate_open := false
var feedback = preload("res://modules/ui/feedback_priority.gd").new()
var toast := TEXT.t("intro_objective")
var coolant_canister: StaticBody3D
var coolant_release: Node3D
var coolant_consumed := false
var coolant_releases := 0
var _coolant_hint_shown := false
var edge_warnings: Array[Control] = []
var toast_time := 6.0
var save_error := false
var _shown_combat_hints: Dictionary = {}
var _combat_hint_cooldown := 0.0
var _interact_was := false
var checkpoint_pos := ROUTE.CHECKPOINT_POS
var cache_pos := ROUTE.CACHE_POS

func _ready() -> void:
	feedback.offer(toast, 0, toast_time)
	main=get_parent()
	player=main.player
	name="LaborRoute"
	var hud_layer:=CanvasLayer.new()
	hud_layer.name="CombatHUDLayer"
	add_child(hud_layer)
	combat_hud=preload("res://modules/ui/combat_hud.gd").new()
	hud_layer.add_child(combat_hud)
	overseer_hud=preload("res://modules/ui/overseer_status.gd").new()
	hud_layer.add_child(overseer_hud)
	ammo_hud=preload("res://modules/ui/ammo_hud.gd").new()
	hud_layer.add_child(ammo_hud)
	for side in [-1, 1]:
		var warning = preload("res://modules/ui/edge_threat_indicator.gd").new()
		warning.name = "ThreatLeft" if side < 0 else "ThreatRight"
		hud_layer.add_child(warning)
		warning.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		edge_warnings.append(warning)
	main.get_node("HUD").hide()
	_setup_input()
	_load_progress()
	if _economy_migrated:_save_progress()
	for key in ["Ground","Plat1","Plat2","Plat3","Enemy1","Enemy2","Enemy3"]:
		var old:=main.get_node_or_null(key)
		if old:
			main.remove_child(old)
			old.queue_free()
	_build_route()
	arm_pickup = preload("res://modules/world/arm_pickup.gd").new()
	arm_pickup.position = ROUTE.ARM_PICKUP_POS
	add_child(arm_pickup)
	arm_pickup.set_collected(equipment.owns("robot_arm"))
	var dressing:=preload("res://lab_dressing.gd").new()
	dressing.name="LabDressing";add_child(dressing)
	var damaged_cable = preload("res://modules/visuals/damaged_cable.gd").new()
	damaged_cable.name = "DamagedCable"
	damaged_cable.position = ROUTE.DAMAGED_CABLE_POS
	add_child(damaged_cable)
	arena_gate=preload("res://modules/combat/arena_gate.gd").new()
	arena_gate.entry_x=MISSION.BOSS_ENTRY_X-.35
	arena_gate.name="ArenaEntryGate";add_child(arena_gate)
	service_return=preload("res://modules/world/service_return.gd").new()
	service_return.lift_x=MISSION.EXIT_X+1
	service_return.name="ServiceReturn";add_child(service_return)
	service_return.unlocked="brute" in cleared
	_spawn_shortcut()
	power_sector=preload("res://modules/world/power_sector.gd").new()
	power_sector.route=self;power_sector.circuits=7 if shortcut_open else int(power_state.get("circuits",0));power_sector.defeated=power_state.get("defeated",[]).duplicate();add_child(power_sector)
	_spawn_supply_crates()
	_spawn_throwables()
	_spawn_wing_drones()
	_spawn_sentinels()
	_hang_awakening_blank()
	_start_escape_alarm.call_deferred()
	squad=preload("res://modules/combat/squad_director.gd").new();squad.name="SquadDirector";squad.player=player;add_child(squad)
	voice=preload("res://modules/audio/robot_voice.gd").new();voice.name="RobotVoice";voice.route=self;add_child(voice)
	for id in pending_shards:_spawn_shard_pickup(id)
	_spawn_security_cover()
	_build_freight_rooms()
	_spawn_coolant_canister()
	# Standing props block the floor strip once their transforms are final.
	for prop in [arm_pickup,checkpoint_console,relay_console,get_node("Workbench"),get_node("EntryWorkbench")]:
		_solid_footprint.call_deferred(prop)
	if armor:_equip_armor(false)
	if shield:_equip_shield(false)
	if shield and shield_kind=="riot":player.take_shield("riot")
	player.gun_mods=gun_mods.duplicate(true);ammo_hud.player=player
	if equipment.owns("lab_armor") and armor_display:armor_display.hide()
	if equipment.owns("salvage_shield") and shield_display:shield_display.hide()
	player.equip_weapon(equipment.equipped_weapon())
	player.set_arm_servo(equipment.prefixes.installed("reinforced_arm")=="servo_i")
	player.guard_contact.connect(_guard_feedback)
	player.hp=player.max_hp
	for spec in MISSION.ENCOUNTERS:
		if spec.id in cleared:continue
		var behaviour: Script=preload("res://modules/combat/lab_overseer.gd") if spec.id=="brute" else load(spec.script) if spec.has("script") else null
		var foe: CharacterBody3D=main._make_enemy(spec.x,spec.role,behaviour,spec.get("gun",""),spec.get("shield",false))
		if spec.id=="brute":overseer=foe
		foe.encounter_id=spec.id
		foe.territory_min_x=spec.min_x
		# Engaged, it follows Rend 4 m further, but stops 2 m short of a checkpoint (safe ground).
		var safe:=-INF
		for x in [checkpoint_pos.x,RELAY_CHECKPOINT_POS.x]:if x<spec.min_x:safe=maxf(safe,x+2.0)
		if spec.id!="brute":foe.pursuit_min_x=maxf(spec.min_x-4.0,safe)
		foe.defeated.connect(_enemy_defeated)
		if foe.has_node("RoleLabel"):foe.get_node("RoleLabel").hide()
		enemies.append(foe)
	servo_trial=preload("res://modules/loot/servo_trial.gd").new()
	servo_trial.name="ServoRecoveryTrial";servo_trial.route=self;add_child(servo_trial)
	main.spawn_point=RELAY_CHECKPOINT_POS if relay_checkpoint else checkpoint_pos if checkpoint else Vector3(0,0.1,0)
	player.global_position=main.spawn_point
	_last_grounded=main.spawn_point
	_cache_marker=preload("res://modules/visuals/shard_cache_marker.gd").new()
	add_child(_cache_marker)
	_refresh_cache_marker()
	main.get_node("Camera3D").global_position=player.global_position+main.follow_offset
	if MISSION.all_cleared(cleared):_open_gate()
	if OS.get_environment("V26_TEST")=="1":
		var runner:=preload("res://tests/cleaver_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	elif OS.get_environment("V24_TEST")=="1":
		var runner:=preload("res://tests/hud_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	elif OS.get_environment("H19_TEST")=="1":
		var runner:=preload("res://tests/landing_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	elif OS.get_environment("V17_TEST")=="1":
		var runner:=preload("res://tests/ranged_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	elif OS.get_environment("H16_TEST")=="1":
		var runner:=preload("res://tests/shortcut_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	elif OS.get_environment("V15_TEST")=="1":
		var runner:=preload("res://tests/equipment_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	elif OS.get_environment("V14_TEST")=="1":
		var runner:=preload("res://tests/guard_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	elif OS.get_environment("V13_TEST")=="1":
		var runner:=preload("res://tests/loot_integration_test.gd").new()
		add_child(runner)
		runner.call_deferred("run")
	elif OS.get_environment("V12_TEST")=="1":
		var runner:=preload("res://tests/route_v12_test.gd").new()
		add_child(runner)
		runner.call_deferred("run")

func _setup_input() -> void:
	if InputMap.has_action("interact"):return
	InputMap.add_action("interact")
	var key:=InputEventKey.new();key.physical_keycode=KEY_E
	InputMap.action_add_event("interact",key)
	var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_Y
	InputMap.action_add_event("interact",pad)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F1:
		help_visible=not help_visible
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_PAGEDOWN:
		_playtest_jump();get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	var boss_alive: bool = is_instance_valid(overseer) and not overseer._dead
	overseer_hud.update_state(boss_alive and overseer.active,overseer.hp if boss_alive else 0,12,overseer.phase if boss_alive else 1,boss_alive and overseer._braced_attack and overseer._state in [overseer.WINDUP,overseer.SWING])
	_update_edge_warnings()
	var pressed:=Input.is_action_pressed("interact")
	var use:=pressed and not _interact_was
	_interact_was=pressed
	feedback.tick(delta)
	toast = feedback.current_text()
	toast_time = feedback.remaining()
	_combat_hint_cooldown=maxf(0,_combat_hint_cooldown-delta)
	_wake_wing_drones()
	_call_reinforcements()
	_announce_progress()
	_check_awakening()
	# The maintenance door slides open as Rend walks up to it (no power puzzle any more).
	if shortcut and not shortcut_open and not player._dying and absf(player.global_position.x-shortcut_pos.x)<1.5:
		shortcut.try_open(Vector3(player.global_position.x,shortcut_pos.y,shortcut_pos.z))  # any depth lane
	if armor_display and is_instance_valid(armor_display) and not equipment.owns("lab_armor"):
		armor_display.rotation.y+=delta*0.65
	var prompt:=""
	arm_pickup.set_focused(can_collect_start_arm())
	if not player._dying:
		if can_collect_start_arm():
			prompt=TEXT.t("prompt_take_arm")
			if use: collect_start_arm()
		elif death_cache.is_active() and reach_distance(death_cache.position())<1.3:
			prompt=TEXT.t("prompt_recover_shards")%death_cache.amount()
			if use:reclaim_shards()
		elif completed and not service_return.prompt(player.global_position).is_empty():
			prompt=service_return.prompt(player.global_position)
			if use:service_return.interact(player.global_position)
		elif _shield_pickup_in_reach():
			var lying=_shield_pickup_in_reach()
			prompt=TEXT.t("prompt_take_shield")%[lying.label(),TEXT.t("prompt_take_shield_swap") if player.shield_unlocked else ""]
			if use:
				var at:Vector3=lying.global_position;var kind:String=lying.kind;lying.queue_free()
				var old:String=player.take_shield(kind)
				shield=true;shield_kind=kind;_save_progress()
				if not old.is_empty() and old!=kind:preload("res://modules/combat/shield_pickup.gd").drop(self,at+Vector3(-player.facing*0.4,0,0),old)
				_message(TEXT.t("msg_riot_shield_equipped")%lying.label() if kind=="riot" else TEXT.t("msg_salvage_shield_equipped"),3.0,1)
		elif _gun_pickup_in_reach():
			var pickup=_gun_pickup_in_reach()
			prompt=TEXT.t("prompt_take_gun")%pickup.label()
			if use:
				var at:Vector3=pickup.global_position
				var had:bool=player.holstered.values().any(func(h):return h.kind==pickup.kind)
				var replaced:Dictionary=player.equip_gun(pickup.kind,pickup.ammo);pickup.queue_free()
				# The gun it replaces goes down where the new one lay.
				if not replaced.is_empty():preload("res://modules/combat/gun_pickup.gd").drop(self,at+Vector3(-player.facing*0.3,0,0),replaced.kind,replaced.ammo)
				if had:_message(TEXT.t("msg_ammo_added")%[pickup.ammo,pickup.label()],2.0,1)
				else:_message(TEXT.t("msg_gun_taken")%[pickup.label(),pickup.ammo],3.0,1)
		elif player.carried:
			prompt=TEXT.t("prompt_carry_crate")
			if use:player.drop_carried()
		elif player.throwable_in_reach():
			prompt=TEXT.t("prompt_lift_crate")
			if use:player.pick_up(player.throwable_in_reach())
		elif not equipment.owns("lab_armor") and reach_distance(cache_pos)<1.6:
			prompt=TEXT.t("prompt_take_armor")
			if use:
				_equip_armor(true)
		elif not equipment.owns("salvage_shield") and reach_distance(shield_pos)<1.3:
			prompt=TEXT.t("prompt_take_salvage_shield")
			if use:_equip_shield(true)
		elif reach_distance(RELAY_CHECKPOINT_POS)<1.3:
			var secured:bool="freight_raider" in cleared and "freight_duelist" in cleared
			prompt=TEXT.t("prompt_relay_secure") if secured else TEXT.t("prompt_relay_locked")
			if use and secured:
				checkpoint=true;relay_checkpoint=true
				main.spawn_point=RELAY_CHECKPOINT_POS;player.hp=player.max_hp
				_save_progress();relay_console.flash_result(not save_error)
				_message(TEXT.t("msg_relay_save_failed") if save_error else TEXT.t("msg_relay_secured"),5.0,3 if save_error else 1)
		elif reach_distance(GUN_BENCH_POS)<1.2:
			prompt=_gun_bench(use)
		elif reach_distance(ENTRY_WORKBENCH_POS)<1.1 and not "first" in cleared:
			prompt=TEXT.t("prompt_workbench_locked")
		elif _near_workbench():
			prompt=TEXT.t("prompt_workbench_open")
			if use:_use_workbench()
		elif reach_distance(checkpoint_pos)<1.6:
			prompt=TEXT.t("prompt_checkpoint")
			if use:
				checkpoint=true;relay_checkpoint=false
				main.spawn_point=checkpoint_pos
				player.hp=player.max_hp
				_save_progress()
				checkpoint_console.flash_result(not save_error)
				_message(TEXT.t("msg_checkpoint_save_failed") if save_error else TEXT.t("msg_checkpoint_saved"), 5.0, 3 if save_error else 1)
		elif player.global_position.x>MISSION.EXIT_X-4 and not gate_open:
			prompt=TEXT.t("prompt_exit_locked")
		elif gate_open and player.global_position.x>MISSION.EXIT_X and not completed:
			completed=true
			_save_progress()
			_message(TEXT.t("msg_sector_secured"),12,3)
			main.pause_controller.show_completion({"guards_defeated":MISSION.cleared_count(cleared),"guards_total":MISSION.ENCOUNTERS.size(),"shards":shards,"weapon_name":ITEMS.label(player.weapon_id) if not player.weapon_id.is_empty() else TEXT.t("label_unarmed"),"armor_name":TEXT.t("label_lab_armor") if armor else TEXT.t("label_no_armor"),"save_ok":not save_error})
	if prompt.is_empty() and toast_time<=0 and not completed and not player._dying:
		_offer_combat_hint()
	var zone:=MISSION.zone(player.global_position.x)
	var state:={"hp":player.hp,"max_hp":player.max_hp,"stamina":player.guard.stamina,
		"shield_unlocked":shield,"weapon_name":player.slot_summary(),
		"armor_name":TEXT.t("label_lab_armor") if armor else TEXT.t("label_no_armor"),"shards":shards,"servo":equipment.prefixes.servo,"servo_unlocked":equipment.owns("reinforced_arm"),
		"guards_defeated":MISSION.cleared_count(cleared),"guards_total":MISSION.ENCOUNTERS.size(),"zone":zone,
		"objective":(TEXT.t("objective_recover_shards")%["←" if death_cache.position().x<player.global_position.x else "→",death_cache.amount()]) if death_cache.is_active() else TEXT.t("objective_sector_secured") if completed else _mission_objective(),
		"prompt":prompt,"feedback":toast if toast_time>0 else "",
		"save_error":save_error,"help_visible":help_visible}
	if state!=_hud_state:
		combat_hud.update_state(state)
		_hud_state=state

func _offer_combat_hint() -> void:
	# Only accepted messages count as taught; saves/danger may temporarily suppress them.
	if is_instance_valid(overseer) and not overseer._dead and overseer._braced_attack and overseer._state==overseer.WINDUP and not _shown_combat_hints.has("brace"):
		var advice:=TEXT.t("advice_parry_or_dodge") if shield else TEXT.t("advice_dodge")
		if _message(TEXT.t("msg_overseer_braced")+advice,4.0,2):
			_shown_combat_hints["brace"]=true
			_combat_hint_cooldown=4.0
		return
	if _combat_hint_cooldown>0:return
	for foe in enemies:
		if not is_instance_valid(foe) or foe._dead or foe._state!=foe.WINDUP:continue
		if absf(foe.global_position.x-player.global_position.x)>5 or absf(foe.global_position.y-player.global_position.y)>1.8:continue
		var kind:="low" if foe._committed_low else "high"
		if foe.role==2 and foe!=overseer:kind="dodge"
		elif foe.role==3:
			if not foe._ranged_attack:continue
			kind="crouch"
		var key:="%d:%s"%[foe.role,kind]
		if _shown_combat_hints.has(key):continue
		var hint:=preload("res://modules/ui/combat_hint_text.gd").text_for(foe.role,kind,shield)
		if hint.is_empty():continue
		if _message(hint,3.5,0):
			_shown_combat_hints[key]=true
			_combat_hint_cooldown=4.0
		return
	# Environment advice follows an imminent attack explanation, not the reverse.
	if not coolant_consumed and not _coolant_hint_shown and absf(player.global_position.x - ROUTE.COOLANT_CANISTER_POS.x) < 3.5:
		if _message(TEXT.t("msg_coolant_hint"), 3.5, 0):
			_coolant_hint_shown=true
			_combat_hint_cooldown=4.0

func _message(text: String, duration:=5.0, priority:=1) -> bool:
	var accepted:bool=feedback.offer(text, priority, duration)
	if accepted:
		toast=feedback.current_text();toast_time=feedback.remaining()
	return accepted

# A half-built humanoid hangs over the corridor; as Rend passes beneath, it drops off its
# hook, rights itself and attacks (the plant activates whatever it has).
const AWAKENING_X := ROUTE.AWAKENING_X
var awakening: Node3D
var awakened: CharacterBody3D
func _hang_awakening_blank() -> void:
	if "duelist" in cleared and "guard" in cleared:return
	awakening = Node3D.new();awakening.name = "AwakeningBlank";add_child(awakening)
	awakening.position = Vector3(AWAKENING_X, 2.35, -0.55)
	var hook := MeshInstance3D.new();var rod := CylinderMesh.new();rod.top_radius = .02;rod.bottom_radius = .02;rod.height = 2.1
	hook.mesh = rod;hook.position.y = 2.75;hook.material_override = _material(Color(.3, .32, .34), .8);awakening.add_child(hook)
	var blank := preload("res://assets3d/characters/light_humanoid_severable_v1/model.glb").instantiate() as Node3D
	blank.name = "Blank";awakening.add_child(blank);blank.rotation.y = PI / 2
	var primer := StandardMaterial3D.new();primer.albedo_color = Color(.44, .45, .46);primer.metallic = .35;primer.roughness = .62
	for m in blank.find_children("*", "MeshInstance3D", true, false):m.material_override = primer
	var player_anim := blank.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player_anim:player_anim.stop()

func _check_awakening() -> void:
	if not is_instance_valid(awakening) or player._dying:return
	if absf(player.global_position.x - AWAKENING_X) > 1.6:return
	var hanging := awakening;awakening = null
	var blank := hanging.get_node("Blank") as Node3D
	var tw := create_tween()
	tw.tween_property(blank, "position:y", -2.3, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		FX.add_shake(0.5);FX.play("land_metal", 0.7, 0.0);FX.metal_contact(Vector3(AWAKENING_X, .1, -.55), Vector3.UP)
		awakened = main._make_enemy(AWAKENING_X, 0)
		awakened.encounter_id = "awakened_blank";awakened.global_position.z = -0.55;awakened.hp = 2
		awakened.territory_min_x = AWAKENING_X - 12.0
		if awakened._body_mesh:
			var primer := StandardMaterial3D.new();primer.albedo_color = Color(.44, .45, .46);primer.metallic = .35;primer.roughness = .62
			awakened._body_mesh.material_override = primer
		if awakened.has_node("RoleLabel"):awakened.get_node("RoleLabel").hide()
		awakened.defeated.connect(_last_of_the_fight)
		awakened.provoke()
		if is_instance_valid(voice):voice.say(awakened, "intruder", true)
		_message(TEXT.t("msg_blank_awakens"), 2.0, 2)
		hanging.queue_free())

# The last robot of a fight goes down in a beat of slow motion.
func _last_of_the_fight(fallen: Node3D) -> void:
	for foe in get_tree().get_nodes_in_group("enemies"):
		if foe==fallen or foe.get("_dead")!=false or not foe.is_physics_processing():continue
		if absf(foe.global_position.x-player.global_position.x)<14.0 and foe._state in [foe.CHASE,foe.WINDUP,foe.SWING,foe.RECOVERY]:return
	FX.slowmo(0.55,0.28);FX.add_shake(0.4)

func _enemy_defeated(enemy: CharacterBody3D) -> void:
	_last_of_the_fight(enemy)
	if enemy.encounter_id in cleared:return
	cleared.append(enemy.encounter_id)
	if enemy.encounter_id=="brute":service_return.unlocked=true
	if enemy.encounter_id=="first":
		if is_instance_valid(alarm):alarm.stop()
		# Reveal salvage before crediting it; keep the reward durable across reloads.
		var origin:=enemy.global_position
		var ray:=PhysicsRayQueryParameters3D.create(origin+Vector3.UP*.5,origin+Vector3.DOWN*6,1)
		var floor_hit:=get_world_3d().direct_space_state.intersect_ray(ray)
		first_salvage_position=(floor_hit.position if not floor_hit.is_empty() else Vector3(origin.x,0,0))+Vector3(0,.28,0)
		first_salvage_position.z=0
		pending_shards[FIRST_SALVAGE_ID]=3
		_spawn_shard_pickup(FIRST_SALVAGE_ID)
		_message(TEXT.t("msg_first_guard_destroyed"),4.0,1)
	else:
		shards=mini(999999,shards+3)
	if MISSION.all_cleared(cleared):
		_open_gate()
		_message(TEXT.t("msg_exit_open"),5.0,2)
	_save_progress()

func _equip_armor(heal: bool) -> void:
	var first_found:bool=not equipment.owns("lab_armor")
	equipment.grant("lab_armor");equipment.equip("armor","lab_armor")
	armor=true
	player.max_hp=7
	if heal and first_found:player.hp=mini(7,player.hp+2)
	if armor_display:armor_display.hide()
	var sk: Skeleton3D=player._hero_skel
	if sk and not sk.has_node("LaborArmor"):
		var armor_root:=Node3D.new();armor_root.name="LaborArmor";sk.add_child(armor_root)
		for side in ["Left","Right"]:
			var socket:=BoneAttachment3D.new();socket.name="ArmorSocket"+side;socket.bone_name="mixamorig_"+side+"Arm"
			sk.add_child(socket)
			var plate: Node3D=load("res://assets3d/weapons/lab_shoulder_plate.glb").instantiate()
			plate.name="LaborShoulderPlate";plate.position.y=0.07
			socket.add_child(plate)
	if sk:
		for side in ["Left","Right"]:
			var socket=sk.get_node_or_null("ArmorSocket"+side)
			if socket:socket.show()
	if heal:
		_save_progress()
		_message(TEXT.t("msg_armor_equipped"))

func _open_gate() -> void:
	gate_open=true
	gate.get_node("Collision").set_deferred("disabled",true)
	create_tween().tween_property(gate,"position:y",9.0,0.8).set_trans(Tween.TRANS_CUBIC)

func _load_progress() -> void:
	if OS.get_environment("V12_TEST")=="1" or OS.get_environment("V13_TEST")=="1" or OS.get_environment("V14_TEST")=="1" or OS.get_environment("V15_TEST")=="1" or OS.get_environment("H16_TEST")=="1" or OS.get_environment("V17_TEST")=="1" or not FileAccess.file_exists(SAVE_PATH):return
	var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	_restore_progress(data)

func _restore_progress(data: Variant) -> void:
	if not data is Dictionary or data.get("version")!=12:return
	if data.get("layout_revision",1)==1:_economy_migrated=true
	data=preload("res://modules/persistence/notstrom_save_migration.gd").migrate(data)
	var raw_power:Variant=data.get("power_sector",{})
	if raw_power is Dictionary:
		var mask:Variant=raw_power.get("circuits",0)
		if (mask is int or mask is float) and is_finite(float(mask)) and float(mask)==floorf(float(mask)) and mask>=0 and mask<=7:power_state["circuits"]=int(mask)
		power_state["defeated"]=[]
		if raw_power.get("defeated",[]) is Array:
			for id in raw_power.get("defeated",[]):
				if id in ["maintenance_guard","maintenance_drone_0","maintenance_drone_1"] and not id in power_state.defeated:power_state.defeated.append(id)
	servo_run.import_state(data.get("servo_run", {}))
	death_cache.reset()
	if data.has("death_cache"):
		death_cache.import_state(data.death_cache)
		if death_cache.is_active() and not _valid_cache_position(death_cache.position()):death_cache.reset()
	var amount=data.get("shards",0)
	shards=clampi(int(amount),0,999999) if amount is float or amount is int else 0
	if data.get("broken_crates") is Array:
		for id in data.broken_crates:
			if id in CRATE_POSITIONS and not id in broken_crates:broken_crates.append(id)
	pending_shards.clear()
	var pending=data.get("pending_shards",{})
	if pending is Dictionary:
		for id in pending:
			var reward=pending[id]
			if id in CRATE_POSITIONS and id in broken_crates and (reward is int or reward is float):
				if is_finite(float(reward)) and float(reward)==floorf(float(reward)) and reward>0 and reward<=99:
					pending_shards[id]=int(reward)
	coolant_consumed=data.get("coolant_consumed",false)==true
	shortcut_open=data.get("shortcut_open",false)==true
	shield=data.get("shield",false)==true
	shield_kind=str(data.get("shield_kind","salvage")) if str(data.get("shield_kind","salvage")) in ["salvage","riot"] else "salvage"
	gun_mods.clear()
	var saved_mods=data.get("gun_mods",{})
	if saved_mods is Dictionary:
		var gun_script=preload("res://modules/combat/gun.gd")
		for kind in saved_mods:
			if kind in gun_script.SPECS and saved_mods[kind] is Array:
				gun_mods[kind]=saved_mods[kind].filter(func(m):return m is String and m in gun_script.MODS)
	var state=data.get("equipment",{})
	equipment.import_state(state if state is Dictionary else {})
	equipment.shards=shards
	armor=data.get("armor",false)==true
	# Old flags meant both ownership and equipped. New saves preserve empty slots.
	var loadout_version: Variant = state.get("loadout_version", 0) if state is Dictionary else 0
	# JSON.parse_string returns numeric floats; membership in an integer array is strict.
	var has_slot_state: bool = (loadout_version is int or loadout_version is float) and loadout_version in [1.0, 2.0, 3.0]
	if loadout_version is int: has_slot_state = loadout_version in [1, 2, 3]
	if not has_slot_state:
		if shield:equipment.grant("salvage_shield");equipment.equip("shield","salvage_shield")
		if armor:equipment.grant("lab_armor");equipment.equip("armor","lab_armor")
	shield=equipment.equipped("shield")=="salvage_shield"
	armor=equipment.equipped("armor")=="lab_armor"
	checkpoint=data.get("checkpoint",false)==true
	completed=data.get("completed",false)==true
	if data.get("cleared") is Array:
		for id in data.cleared:
			if id in MISSION.encounter_ids() and not id in cleared:cleared.append(id)
	# Legacy saves already received enemy credits: only an explicit pending record
	# creates a drop. A cleared encounter alone must never award it again.
	var saved_drop=data.get("first_salvage_position",[])
	if "first" in cleared and pending is Dictionary and pending.get(FIRST_SALVAGE_ID)==3 and saved_drop is Array and saved_drop.size()==3:
		var numeric:=true
		for component in saved_drop:
			if not (component is float or component is int):numeric=false
		if numeric:
			var at:=Vector3(saved_drop[0],saved_drop[1],saved_drop[2])
			if _valid_cache_position(at-Vector3(0,.28,0)):
				first_salvage_position=at;pending_shards[FIRST_SALVAGE_ID]=3
	relay_checkpoint=checkpoint and data.get("relay_checkpoint",false)==true and "freight_raider" in cleared and "freight_duelist" in cleared
	if data.get("economy_revision",0)!=1:
		shards=mini(999999,shards+3*cleared.size())
		equipment.shards=shards
		_economy_migrated=true

func _save_progress() -> void:
	equipment.shards=shards
	var path:=SAVE_PATH if OS.get_environment("V12_TEST")!="1" and OS.get_environment("V13_TEST")!="1" and OS.get_environment("V14_TEST")!="1" and OS.get_environment("V15_TEST")!="1" and OS.get_environment("V17_TEST")!="1" else "user://rendrun_route_v12_test.json"
	save_error=preload("res://modules/persistence/equipment_save_guard.gd").write_json(path,{"version":12,"layout_revision":MISSION.REVISION,"shortcut_open":shortcut_open,"economy_revision":1,"equipment":equipment.export_state(),"servo_run":servo_run.export_state(),"power_sector":{"circuits":power_sector.circuits,"defeated":power_sector.defeated.duplicate()} if is_instance_valid(power_sector) else power_state,"shield":shield,"shield_kind":shield_kind,"gun_mods":gun_mods.duplicate(true),"armor":armor,"checkpoint":checkpoint,"relay_checkpoint":relay_checkpoint,"completed":completed,"cleared":cleared,"shards":shards,"broken_crates":broken_crates,"pending_shards":pending_shards.duplicate(),"first_salvage_position":[first_salvage_position.x,first_salvage_position.y,first_salvage_position.z],"coolant_consumed":coolant_consumed,"death_cache":death_cache.export_state()})!=OK
	if not save_error and is_instance_valid(checkpoint_console):checkpoint_console.set_saved(checkpoint and not relay_checkpoint)
	if not save_error and is_instance_valid(relay_console):relay_console.set_saved(relay_checkpoint)

func _material(color: Color, metal:=0.0, glow:=false) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.metallic=metal;mat.roughness=0.55
	if glow:
		mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=1.1
	return mat

func _box(label: String, pos: Vector3, size: Vector3, color: Color, solid:=false, glow:=false) -> Node3D:
	var node: Node3D=StaticBody3D.new() if solid else Node3D.new()
	node.name=label
	node.set_meta("construction_label",label)
	var mi:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;mi.mesh=mesh
	mi.material_override=_material(color,0.35,glow);node.add_child(mi)
	if solid:
		var shape:=BoxShape3D.new();shape.size=size;var col:=CollisionShape3D.new();col.name="Collision";col.shape=shape;node.add_child(col)
	add_child(node);node.position=pos
	return node

func _build_route() -> void:
	var foundation=_box("Foundation",Vector3(39,-0.3,0),Vector3(88,0.6,5),Color(0.075,0.09,0.12),true)
	# Keep the continuous collider; split only its visual to expose recessed tiles.
	foundation.get_child(0).visible=false
	_box("FoundationWest",Vector3(-2.75,-0.3,0),Vector3(4.5,0.6,5),Color(0.075,0.09,0.12))
	_box("FloorSubstructure",Vector3(5.5,-0.36,0),Vector3(12,0.48,3.8),Color(0.075,0.09,0.12))
	_box("FoundationEast",Vector3(47.25,-0.36,0),Vector3(71.5,0.48,3.8),Color(0.075,0.09,0.12))
	_box("WestBoundary",Vector3(-4,2,0),Vector3(0.5,4,5),Color(0.08,0.11,0.15),true)
	_box("EastBoundary",Vector3(MISSION.EAST_X,2,0),Vector3(0.5,4,5),Color(0.08,0.11,0.15),true)
	# Continuous rear substrate; structural bays change by function, not random scatter.
	# Real visual opening x[-1.3,3.2], y[1.1,3.8]; no physics changed.
	for spec in [["RearShellWest",Vector3(-3.15,3.5,-2.3),Vector3(3.7,7,.35)],["RearShellEast",Vector3(43.1,3.5,-2.3),Vector3(79.8,7,.35)],["RearShellSill",Vector3(.95,.55,-2.3),Vector3(4.5,1.1,.35)],["RearShellHeader",Vector3(.95,5.4,-2.3),Vector3(4.5,3.2,.35)]]:
		_box(spec[0],spec[1],spec[2],Color(.035,.055,.075))
	_box("Ceiling",Vector3(39,7,0),Vector3(88,0.3,5),Color(0.065,0.08,0.10))
	for x in range(-2,int(MISSION.EAST_X),3):
		if x>=1:
			var tile=preload("res://assets3d/env/h41_floor_v1/model.glb").instantiate()
			tile.name=("FirstRoomFloor%d" if x<=10 else "LaborFloor%d")%x;tile.position=Vector3(x,0,0);add_child(tile)
		else:
			_box("FloorPanel",Vector3(x,-0.012,0),Vector3(2.95,0.024,3.8),Color(0.14,0.16,0.19))
		if x!=1:_box("Pilaster",Vector3(x,3.4,-2.02),Vector3(0.16,6.8,0.24),Color(0.09,0.13,0.16))
		if x>=4:_box("WallInset",Vector3(x+1.4,2.5,-2.09),Vector3(2.4,2.8,0.12),Color(0.055,0.09,0.12))
		_box("GuideLight",Vector3(x+0.9,0.12,-1.86),Vector3(1.35,0.035,0.05),TEAL,false,true)
		_box("Duct",Vector3(x,4.5,-1.8),Vector3(3,0.22,0.35),Color(0.16,0.20,0.22))
	_box("CachePlinth",cache_pos+Vector3(0,0.22,-0.45),Vector3(0.8,0.44,0.65),Color(0.10,0.15,0.18))
	armor_display=load("res://assets3d/weapons/lab_shoulder_plate.glb").instantiate()
	add_child(armor_display);armor_display.position=cache_pos+Vector3(0,0.61,-0.45);armor_display.scale=Vector3.ONE*1.5
	checkpoint_console=preload("res://modules/world/checkpoint_console.gd").new()
	checkpoint_console.name="CheckpointConsole"
	checkpoint_console.position=ROUTE.CHECKPOINT_CONSOLE_POS
	checkpoint_console.set_saved(checkpoint and not relay_checkpoint)
	add_child(checkpoint_console)
	shield_display=preload("res://shield_visual.gd").new();add_child(shield_display)
	shield_display.position=shield_pos+Vector3(0,0.48,-0.2)
	var workbench_visual = preload("res://assets3d/env/workbench_v1/model.glb").instantiate()
	workbench_visual.name = "Workbench"
	add_child(workbench_visual)
	workbench_visual.position = workbench_pos + Vector3(0,0,-0.55)
	var entry_bench=preload("res://assets3d/env/rework_station_v1/model.glb").instantiate()
	entry_bench.name="EntryWorkbench";add_child(entry_bench)
	entry_bench.position=ENTRY_WORKBENCH_POS+Vector3(0,0,-.75)
	var gun_bench=preload("res://assets3d/env/rework_station_v1/model.glb").instantiate()
	gun_bench.name="GunBench";add_child(gun_bench)
	gun_bench.position=GUN_BENCH_POS+Vector3(0,0,-.75)
	var gun_label:=Label3D.new();gun_label.name="GunBenchLabel"
	gun_label.text=TEXT.t("sign_armory");gun_label.font_size=22;gun_label.pixel_size=.003;gun_label.outline_size=0
	gun_label.modulate=Color(.35,.18,.05);gun_label.position=GUN_BENCH_POS+Vector3(-.25,.698,-.324);add_child(gun_label)
	var bench_lamp:=SpotLight3D.new();bench_lamp.name="GunBenchLamp";bench_lamp.light_color=Color(1,.68,.35);bench_lamp.light_energy=2.5
	bench_lamp.spot_range=3.5;bench_lamp.spot_angle=32;bench_lamp.position=GUN_BENCH_POS+Vector3(0,2.6,-.5);bench_lamp.rotation.x=-PI/2;add_child(bench_lamp)
	var bench_label:=Label3D.new();bench_label.name="UpgradeLabel"
	bench_label.text=TEXT.t("sign_rework");bench_label.font_size=22;bench_label.pixel_size=.003;bench_label.outline_size=0
	bench_label.modulate=Color(.14,.24,.27);bench_label.position=ENTRY_WORKBENCH_POS+Vector3(-.25,.698,-.324);add_child(bench_label)
	for lamp in ROUTE.SERVICE_LAMPS:
		var x: float = lamp["x"]
		var fixture=preload("res://modules/visuals/service_lamp.gd").new()
		fixture.name="ServiceLamp%d"%int(x)
		fixture.position=Vector3(x,3.2,-1.65)
		fixture.tint=LAMP_TINTS[lamp["tint"]]
		add_child(fixture)
	# Sideways door has a real through-path and a destination chamber, never a fake wall plaque.
	gate=_box("SecurityDoor",Vector3(MISSION.EXIT_X-2,1.6,0),Vector3(0.35,3.2,3.8),Color(0.28,0.12,0.09),true)
	_dress_lock_door(gate)
	var details=preload("res://modules/visuals/world_service_details.gd").new()
	details.name="WorldServiceDetails";add_child(details)

# The exit lock's slab wears the Meshy blast door (asset_library/meshy/2026-10-23_environment)
# under a steel header with a hazard band; the collider is unchanged and rises with it.
func _dress_lock_door(door: Node3D) -> void:
	door.get_child(0).hide()
	var leaf := preload("res://assets3d/env/lock_door_v1/model.glb").instantiate() as Node3D
	leaf.name="BlastDoor";door.add_child(leaf)
	leaf.rotation.y=-PI/2  # model front (+Z) faces the approaching player (-X)
	leaf.scale=Vector3(2.2,2.9,1.6)  # 1.9 x 0.87 m model -> 4.2 x 2.5 m leaf
	leaf.position=Vector3(0,-1.6+1.26,0)
	var header:=MeshInstance3D.new();header.name="DoorHeader"
	var slab:=BoxMesh.new();slab.size=Vector3(.42,.7,4.2);header.mesh=slab
	header.material_override=_material(Color(.07,.08,.09),.35);door.add_child(header);header.position=Vector3(0,1.25,0)
	var band:=MeshInstance3D.new();band.name="HeaderHazard"
	var quad:=PlaneMesh.new();quad.size=Vector2(4.2,.22);quad.orientation=PlaneMesh.FACE_X;band.mesh=quad
	var paint:=ShaderMaterial.new();paint.shader=preload("res://materials/floor_paint.gdshader")
	paint.set_shader_parameter("hazard",true);paint.set_shader_parameter("wear",.15);paint.set_shader_parameter("size",Vector2(4.2,.22))
	band.material_override=paint;door.add_child(band);band.position=Vector3(-.215,1.25,0);band.rotation.y=PI

# Loose supply cases Rend can shove, lift and throw (throwable_crate.gd); placements in route data.
const THROWABLE_STACKS := ROUTE.THROWABLE_STACKS
var throwables: Array[RigidBody3D] = []
# Kamikaze drones over the security wing and the relay corridor; placements in route data.
const WING_DRONES := ROUTE.WING_DRONES
var wing_drones: Array = []
# Sentinels wait in the open wall alcoves (factory_corridor.gd); optional foes, not
# part of the mission count. They wake when Rend runs past.
var sentinels: Array = []
func _spawn_sentinels() -> void:
	for x in preload("res://modules/world/factory_corridor.gd").alcove_xs():
		var sentinel: CharacterBody3D = main._make_enemy(x, 1, preload("res://modules/combat/sentinel.gd"))
		sentinel.encounter_id = "sentinel_%d" % int(x)
		sentinel.global_position = Vector3(x, .05, -2.3)
		sentinel.get_node("VisualPivot").rotation.y = -PI / 2  # faces out of the alcove
		sentinel.territory_min_x = x - 12.0
		sentinel.defeated.connect(_last_of_the_fight)
		sentinels.append(sentinel)

func _spawn_wing_drones() -> void:
	for i in WING_DRONES.size():
		var drone = preload("res://modules/combat/maintenance_drone.gd").new()
		drone.encounter_id = "wing_drone_%d" % i;drone.player = player
		add_child(drone);drone.position = WING_DRONES[i];drone.home = drone.position;drone.timer = 1.0 + i
		wing_drones.append(drone)

func _wake_wing_drones() -> void:
	for drone in wing_drones:
		if is_instance_valid(drone):drone.enabled = absf(player.global_position.x - drone.home.x) < 9.0

# Reinforcements: when an encounter's robot first engages Rend, these run in from off
# screen on the far side of him (he ends up between two fronts). Optional foes outside the
# mission count. encounter id -> [[role, gun, shield], ...]
const REINFORCEMENTS := ROUTE.REINFORCEMENTS
const REINFORCE_DISTANCE := ROUTE.REINFORCE_DISTANCE
var _reinforced := {}
var reinforcements: Array = []
func _call_reinforcements() -> void:
	for foe in enemies:
		if not is_instance_valid(foe) or foe._dead or _reinforced.has(foe.encounter_id) or not foe.is_physics_processing():continue
		if not REINFORCEMENTS.has(foe.encounter_id) or foe._state not in [foe.CHASE, foe.WINDUP, foe.SWING, foe.RECOVERY]:continue
		_reinforced[foe.encounter_id] = true
		var side := -signf(foe.global_position.x - player.global_position.x)
		var i := 0
		for spec in REINFORCEMENTS[foe.encounter_id]:
			var x: float = clampf(player.global_position.x + side * (REINFORCE_DISTANCE + i * 1.4), 1.0, MISSION.EAST_X - 2.0)
			var mate: CharacterBody3D = main._make_enemy(x, spec[0], null, spec[1], spec[2])
			mate.encounter_id = "%s_backup_%d" % [foe.encounter_id, i]
			mate.territory_min_x = minf(x, player.global_position.x) - 6.0
			mate.global_position.z = clampf(player.global_position.z + (0.5 if i % 2 == 0 else -0.5), -1.0, 1.2)
			if mate.has_node("RoleLabel"):mate.get_node("RoleLabel").hide()
			mate.provoke()
			mate.defeated.connect(_last_of_the_fight)
			reinforcements.append(mate);i += 1
		_message(TEXT.t("msg_reinforcements"), 2.0, 1)

# Escape alarm (alarm_sequence.gd) while the first room's guard is still standing.
var alarm: Node3D
var shield_kind := "salvage"  # which shield Rend carries (saved)
var squad: Node  # squad_director.gd: radio, pincer, attack rhythm, fire discipline
var voice: Node  # robot_voice.gd: robot lines and PA announcements
# PA announcements as Rend reaches each part of the plant: [x, key]
const PA_CUES := ROUTE.PA_CUES
var _pa_done := {}
func _announce_progress() -> void:
	if not is_instance_valid(voice) or player._dying:return
	for cue in PA_CUES:
		if player.global_position.x >= cue[0] and not _pa_done.has(cue[1]):
			_pa_done[cue[1]] = true;voice.announce(cue[1]);return
func _start_escape_alarm() -> void:
	if "first" in cleared:return
	alarm=preload("res://modules/world/alarm_sequence.gd").new();alarm.name="EscapeAlarm";add_child(alarm)
	alarm.start()
	get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(voice):voice.announce("escape"))
	_message(TEXT.t("msg_alarm_take_arm"),5.0,2)

func _spawn_throwables() -> void:
	for spec in THROWABLE_STACKS:
		for level in int(spec[1]):
			var crate: RigidBody3D = preload("res://modules/combat/throwable_crate.gd").new()
			crate.name = "Throwable_%d_%d" % [int(spec[0] * 10), level]
			add_child(crate)
			crate.global_position = Vector3(spec[0] + level * .05, .31 + level * .63, -.72)
			crate.rotation.y = PI if int(spec[0]) % 2 == 0 else 0.0
			throwables.append(crate)

# Hermie owns the independent crate module; Codex owns rewards and persistence.
func _spawn_supply_crates() -> void:
	const MODULE := "res://modules/loot/supply_crate.gd"
	if not ResourceLoader.exists(MODULE):return # Worker delivery can be integrated independently.
	var module: Script=load(MODULE)
	for id in CRATE_POSITIONS:
		var crate: StaticBody3D=module.new()
		crate.crate_id=id
		crate.position=CRATE_POSITIONS[id]
		crate.broken.connect(_on_supply_broken)
		crate.restore_broken(id in broken_crates)
		add_child(crate)
		supply_crates.append(crate)

func _on_supply_broken(id: String, amount: int, _origin: Vector3) -> void:
	if not id in CRATE_POSITIONS or id in broken_crates:return
	broken_crates.append(id)
	var reward:=clampi(amount,0,99)
	if reward>0:pending_shards[id]=reward
	_save_progress()
	if reward>0 and is_inside_tree():_spawn_shard_pickup(id)

func _spawn_shard_pickup(id: String) -> void:
	if not pending_shards.has(id) or shard_pickups.has(id):return
	var pickup=preload("res://modules/loot/shard_pickup.gd").new()
	pickup.name="ShardPickup_"+id;pickup.crate_id=id;pickup.player=player
	pickup.amount=int(pending_shards[id])
	pickup.position=first_salvage_position if id==FIRST_SALVAGE_ID else CRATE_POSITIONS[id]+Vector3(0,.28,0)
	pickup.reached.connect(_collect_shard_pickup)
	shard_pickups[id]=pickup;add_child(pickup)

func _collect_shard_pickup(id: String) -> void:
	if not pending_shards.has(id):return
	if is_instance_valid(player) and player._dying:return
	var reward:int=pending_shards[id]
	pending_shards.erase(id)
	shards=mini(999999,shards+reward)
	if shard_pickups.has(id):
		var pickup=shard_pickups[id]
		shard_pickups.erase(id)
		if is_instance_valid(pickup):pickup.queue_free()
	_save_progress()
	if is_inside_tree():
		FX.play("footstep_metal_b",1.65,-12.0)
		_message(TEXT.t("msg_shards_added")%[reward,shards],1.8)
		if save_error:_message(TEXT.t("msg_shards_save_failed"),5.0,3)

func _equip_shield(save: bool) -> void:
	equipment.grant("salvage_shield");equipment.equip("shield","salvage_shield")
	shield=true;player.shield_unlocked=true
	_record_found_shield()
	if shield_display:shield_display.hide()
	if save:
		_save_progress()
		_message(TEXT.t("msg_shield_tutorial"))

func _guard_feedback(outcome: String) -> void:
	_message(TEXT.t("msg_parried") if outcome=="parry" else TEXT.t("msg_shield_broken") if outcome=="break" else TEXT.t("msg_blocked"),1.2,2)

func _record_found_shield() -> void:
	var state: Dictionary=equipment.export_state()
	if not "salvage_shield" in state.owned:state.owned.append("salvage_shield")
	state.shards=shards;equipment.import_state(state)

# Interaction range across the floor strip: depth does not matter, only side and height.
## The weapon bench: with a gun drawn it offers the mods that gun lacks, one at a time
## (guard key cycles), E buys and fits it. Returns the prompt line.
func _gun_bench(use: bool) -> String:
	var gun=player.gun
	if not is_instance_valid(gun):return TEXT.t("bench_draw_gun")
	var missing:Array=gun.MODS.keys().filter(func(m):return not gun.has_mod(m))
	if missing.is_empty():return TEXT.t("bench_fully_modded")%gun.spec().label
	var cycle:=Input.is_action_pressed("guard")
	if cycle and not _bench_guard_was:_bench_pick+=1;FX.play("block",1.8,-14.0)
	_bench_guard_was=cycle
	var mod:String=missing[_bench_pick%missing.size()]
	var info:Dictionary=gun.MODS[mod]
	if use:
		if shards<info.cost:
			_message(TEXT.t("bench_not_enough_shards")%[info.label,info.cost],2.0,1);FX.play("radio_chirp",0.5,-8.0)
		else:
			shards-=info.cost;equipment.shards=shards
			player.fit_mod(gun.kind,mod);gun_mods=player.gun_mods.duplicate(true)
			FX.play("block",0.9,-4.0);FX.metal_contact(GUN_BENCH_POS+Vector3(0,1.0,-.4),Vector3.UP)
			_message(TEXT.t("bench_mod_installed")%[info.label,info.info],3.0,1);_save_progress()
		return ""
	return TEXT.t("bench_prompt_install")%[info.label,info.cost,info.info,TEXT.t("bench_prompt_next_mod") if missing.size()>1 else ""]

func reach_distance(target: Vector3) -> float:
	return Vector2(player.global_position.x - target.x, player.global_position.y - target.y).length()

func _near_workbench() -> bool:
	return reach_distance(workbench_pos)<1.1 or ("first" in cleared and reach_distance(ENTRY_WORKBENCH_POS)<1.1)

func _use_workbench() -> void:
	if player._dying or not _near_workbench():return
	if player._attack_phase>0 or player._dash_left>0 or player.guard.is_guarding():
		_message(TEXT.t("msg_switch_after_action"),1.0);return
	main.pause_controller.open_shop(workbench_state())

func workbench_state(feedback_text := "") -> Dictionary:
	return {"shards":shards,"owned":equipment.export_state().owned,"equipped":equipment.equipped_weapon(),"feedback":feedback_text,"servo":equipment.prefixes.servo,"trial_unlocked":equipment.owns("reinforced_arm") and "first" in cleared,"trial_ready":servo_run.can_begin(),"trial_run":servo_run.run_id,"trial_defeated":servo_run.defeated_count(),"bonus_misses":servo_run.bonus_misses,"servo_owned":equipment.prefixes.owns_module("servo_i"),"servo_installed":equipment.prefixes.installed("reinforced_arm")=="servo_i"}

func _shop_reason_text(reason: String) -> String:
	match reason:
		"not_at_workbench": return TEXT.t("shop_reason_not_at_workbench")
		"busy": return TEXT.t("shop_reason_busy")
		"install": return TEXT.t("shop_reason_install")
		"missing_base": return TEXT.t("shop_reason_missing_base")
		"already_owned": return TEXT.t("shop_reason_already_owned")
		"save_failed": return TEXT.t("shop_save_failed")
		_: return TEXT.t("shop_reason_unknown")

func apply_workbench_action(id:String) -> void:
	var shop:Control=main.pause_controller.shop
	if not shop.visible:return
	if player._dying or not _near_workbench():
		main.pause_controller.resume();return
	if id in ["servo_craft","servo_install","servo_remove"]:
		var result:Dictionary=apply_prefix_action("" if id=="servo_remove" else "servo_i",id!="servo_craft")
		var message:String=TEXT.t("shop_servo_crafted") if id=="servo_craft" else equipment.PREFIXES.summary()+TEXT.t("shop_servo_installed_suffix") if id=="servo_install" else TEXT.t("shop_servo_removed")
		if not result.ok:message=TEXT.t("shop_servo_cannot_buy") if result.reason in ["insufficient_shards","insufficient_servo"] else _shop_reason_text(str(result.reason))
		shop.update_state(workbench_state(message));return
	if id=="servo_trial":
		var trial_result:Dictionary=start_servo_trial()
		if trial_result.ok:main.pause_controller.resume()
		else:shop.update_state(workbench_state(str(trial_result.reason)))
		return
	if id not in ["robot_arm","reinforced_arm"]:
		shop.update_state(workbench_state(TEXT.t("shop_unknown_item")));return
	if _workbench_action_frame==Engine.get_process_frames():
		shop.update_state(workbench_state());return
	equipment.shards=shards
	var message := ""
	if not equipment.owns(id):
		var result:Dictionary=equipment.purchase(id)
		if not result.ok:
			shop.update_state(workbench_state(TEXT.t("shop_missing_shards")%maxi(0,int(equipment.CATALOGUE["reinforced_arm"].cost)-shards)));return
		shards=equipment.shards
		message=TEXT.t("shop_reinforced_arm_bought")
	else:
		if equipment.equipped_weapon()==id:
			shop.update_state(workbench_state(TEXT.t("shop_already_equipped")));return
		if not equipment.equip_weapon(id):return
		player.equip_weapon(id)
		message=TEXT.t("shop_reinforced_arm_equipped") if id=="reinforced_arm" else TEXT.t("shop_robot_arm_equipped")
	_workbench_action_frame=Engine.get_process_frames()
	_save_progress()
	if save_error:message=TEXT.t("shop_save_failed")
	shop.update_state(workbench_state(message))

func apply_prefix_action(module_id: String, install := false) -> Dictionary:
	# Transaction boundary used by the servo workbench.
	if not is_instance_valid(player) or not is_instance_valid(main):
		return {"ok": false, "reason": "not_at_workbench"}
	if not main.pause_controller.shop.visible or not _near_workbench():
		return {"ok": false, "reason": "not_at_workbench"}
	if player._dying or player._attack_phase > 0 or player._dash_left > 0 or player.guard.is_guarding():
		return {"ok": false, "reason": "busy"}
	equipment.shards = shards
	var before: Dictionary = equipment.export_state()
	var result: Dictionary
	if install:
		result = {"ok": equipment.install_module("reinforced_arm", module_id), "reason": "install"}
	else:
		result = equipment.craft_module(module_id)
	if not result.ok: return result
	shards = equipment.shards
	_save_progress()
	if save_error:
		equipment.import_state(before)
		shards = equipment.shards
		return {"ok": false, "reason": "save_failed", "spent": {}}
	player.set_arm_servo(equipment.prefixes.installed("reinforced_arm")=="servo_i")
	return result

func start_servo_trial() -> Dictionary:
	if not equipment.owns("reinforced_arm") or not "first" in cleared:return {"ok":false,"reason":TEXT.t("servo_need_reinforced_arm")}
	if not main.pause_controller.shop.visible or reach_distance(ENTRY_WORKBENCH_POS)>=1.1:return {"ok":false,"reason":TEXT.t("servo_start_at_workbench")}
	if player._dying or player._attack_phase>0 or player._dash_left>0 or player.guard.is_guarding():return {"ok":false,"reason":TEXT.t("servo_finish_action")}
	var before:Dictionary=servo_run.export_state()
	if not servo_run.begin(randi() & 0x7ffffffe):return {"ok":false,"reason":TEXT.t("servo_finish_run")}
	_save_progress()
	if save_error:
		servo_run.import_state(before)
		return {"ok":false,"reason":TEXT.t("servo_save_failed_start")}
	_message(TEXT.t("servo_run_started"),5.0,2)
	return {"ok":true}

func record_servo_arm(epoch:int, at:Vector3) -> bool:
	var before:Dictionary=servo_run.export_state()
	var ground:=at
	if is_inside_tree():
		var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.5,at+Vector3.DOWN*6,1)
		var floor_hit:=get_world_3d().direct_space_state.intersect_ray(query)
		ground=(floor_hit.position if not floor_hit.is_empty() else Vector3(at.x,0,0))+Vector3(0,.28,0)
	ground.z=0
	if not servo_run.expose_servo(epoch,ground):return false
	_save_progress()
	if save_error:servo_run.import_state(before);return false
	return true

func record_servo_defeat(epoch:int, index:int) -> bool:
	var before:Dictionary=servo_run.export_state()
	if not servo_run.defeat(epoch,index):return false
	_save_progress()
	if save_error:
		servo_run.import_state(before)
		_message(TEXT.t("servo_save_failed_paused"),5.0,3)
		return false
	return true

func collect_servo_reward(epoch:int, index:int) -> bool:
	if is_instance_valid(player) and player._dying:return false
	var reward:Dictionary=servo_run.pending(epoch,index)
	if reward.is_empty():return false
	if shards+int(reward.shards)>equipment.MAX_SHARDS or equipment.prefixes.servo+int(reward.servo)>equipment.prefixes.CAP:return false
	var before:Dictionary=servo_run.export_state()
	var before_equipment:Dictionary=equipment.export_state()
	var old_shards:int=shards
	servo_run.collect(epoch,index)
	shards+=int(reward.shards);equipment.prefixes.credit_servo(int(reward.servo))
	_save_progress()
	if save_error:
		servo_run.import_state(before);equipment.import_state(before_equipment);shards=old_shards
		_message(TEXT.t("servo_save_failed_loot"),5.0,3)
		return false
	var parts:PackedStringArray=[]
	if int(reward.shards)>0:parts.append(TEXT.t("servo_reward_shards")%int(reward.shards))
	if int(reward.servo)>0:parts.append(TEXT.t("servo_reward_servo")%int(reward.servo))
	_message(" · ".join(parts),2.0,1)
	return true

func _spawn_shortcut() -> void:
	const MODULE:="res://modules/world/shortcut_door.gd"
	if not ResourceLoader.exists(MODULE):return # H16 worker delivery not yet admitted.
	shortcut=load(MODULE).new()
	shortcut.door_id="maintenance_return"
	shortcut.unlock_from_either_side=true
	shortcut.open_travel=7.0;shortcut.open_time=0.65
	shortcut.position=shortcut_pos
	shortcut.restore_open(shortcut_open)
	shortcut.opened.connect(_shortcut_opened)
	add_child(shortcut)
	_box("ShortcutLiftHousing",shortcut_pos+Vector3(0,8.0,0),Vector3(0.5,1,2.3),Color(0.13,0.16,0.18))

## Playtest helper (debug builds only, Page Down): puts Rend just before the next encounter
## that is still alive, so every robot type can be tried without walking the route.
func _shield_pickup_in_reach() -> Node3D:
	if player._dying or player.carried:return null
	for lying in get_tree().get_nodes_in_group("shield_pickups"):
		if not lying.is_queued_for_deletion() and Vector2(lying.global_position.x-player.global_position.x,lying.global_position.z-player.global_position.z).length()<1.1:return lying
	return null

func _gun_pickup_in_reach() -> Node3D:
	if player._dying or player.carried:return null
	for pickup in get_tree().get_nodes_in_group("gun_pickups"):
		if not pickup.is_queued_for_deletion() and Vector2(pickup.global_position.x-player.global_position.x,pickup.global_position.z-player.global_position.z).length()<1.1:return pickup
	return null

func _playtest_jump() -> void:
	if not OS.is_debug_build() or player._dying:return
	var ahead: Array = enemies.filter(func(e): return is_instance_valid(e) and not e._dead and e.global_position.x > player.global_position.x + 3.0)
	if ahead.is_empty():return
	ahead.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	if not shortcut_open and ahead[0].global_position.x > shortcut_pos.x:shortcut.try_open(Vector3(shortcut_pos.x - 0.8, shortcut_pos.y, shortcut_pos.z))
	player.global_position = Vector3(ahead[0].global_position.x - 4.5, 0.05, 0.0);player.velocity = Vector3.ZERO
	_message(TEXT.t("debug_test_jump") % ahead[0].encounter_id, 2.0, 1)

func _shortcut_opened(id: String) -> void:
	if id!="maintenance_return" or shortcut_open:return
	shortcut_open=true
	_save_progress()
	_message(TEXT.t("msg_shortcut_opened"))

func _spawn_security_cover() -> void:
	var body := StaticBody3D.new()
	body.name = "SecurityCover"
	body.position = ROUTE.SECURITY_COVER_POS
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 1.25, 0.5)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.625
	body.add_child(collision)
	body.add_child(preload("res://modules/visuals/lab_cover_barrier_visual.gd").new())
	add_child(body)

# Only charging, unobstructed ranged attackers outside the horizontal camera
# bounds qualify. Existing world cues remain sufficient for visible attackers.
func _update_edge_warnings() -> void:
	var states := [0, 0] # hidden / acquiring / committed, independently per side
	if not player._dying and not completed and not get_tree().paused:
		var camera: Camera3D = main.get_node("Camera3D")
		var width := get_viewport().get_visible_rect().size.x
		for foe in enemies:
			if not is_instance_valid(foe) or foe._dead or foe._stun > 0:continue
			if foe.role != 3 or not foe._ranged_attack or foe._state != foe.WINDUP:continue
			if (player.global_position.x - foe.global_position.x) * foe._attack_front <= 0:continue
			var point: Vector3 = foe.global_position + Vector3(0, 1.2, 0)
			if camera.is_position_behind(point):continue
			var x := camera.unproject_position(point).x
			if x >= 0 and x <= width:continue
			if not foe._has_fire_lane(player):continue
			var index := 0 if x < 0 else 1
			states[index] = maxi(states[index], 2 if foe._state_t >= 0.55 else 1)
	for i in 2:
		if states[i] == 0:edge_warnings[i].clear()
		else:edge_warnings[i].set_threat(-1 if i == 0 else 1, states[i] == 2)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		for warning in edge_warnings:warning.clear()

# Rend walks in depth now, so standing props need a body: a box around their visual footprint
# on the world layer. Interaction ranges are unaffected (reach_distance ignores depth).
func _solid_footprint(prop: Node3D, inset := 0.04) -> void:
	if not is_instance_valid(prop):return
	var bounds := AABB();var found := false
	for mesh in prop.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree():continue
		var part: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = bounds.merge(part) if found else part;found = true
	if not found:return
	var body := StaticBody3D.new();body.name = prop.name + "Footprint";body.collision_layer = 1;body.collision_mask = 0
	var shape := CollisionShape3D.new();var box := BoxShape3D.new()
	box.size = (bounds.size - Vector3.ONE * inset * 2.0).max(Vector3.ONE * 0.05);shape.shape = box
	body.add_child(shape);add_child(body);body.global_position = bounds.get_center()

func _spawn_coolant_canister() -> void:
	coolant_release = preload("res://modules/vfx/coolant_release_visual.gd").new()
	add_child(coolant_release)
	coolant_canister = preload("res://modules/loot/coolant_canister.gd").new()
	coolant_canister.position = ROUTE.COOLANT_CANISTER_POS
	coolant_canister.restore_broken(coolant_consumed)
	coolant_canister.broken.connect(_on_coolant_broken)
	add_child(coolant_canister)

func _on_coolant_broken(_id: String, _amount: int, origin: Vector3) -> void:
	if coolant_consumed:return
	coolant_consumed = true
	coolant_releases += 1
	_save_progress()
	var center := origin + Vector3(0, 0.7, 0)
	coolant_release.emit_release(center)
	for foe in enemies:
		if not is_instance_valid(foe) or foe._dead:continue
		var target: Vector3 = foe.global_position + Vector3(0, 0.7, 0)
		if center.distance_to(target) > 2.2:continue
		var ray := PhysicsRayQueryParameters3D.create(center, target, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
		foe.interrupt_with_pressure(center)
	_message(TEXT.t("msg_coolant_burst"), 1.5,2)

func _valid_cache_position(at: Vector3) -> bool:
	return at.is_finite() and at.x>=-3.0 and at.x<=MISSION.EAST_X-1 and at.y>=-0.1 and at.y<=6.0 and absf(at.z)<0.1

func _physics_process(_delta: float) -> void:
	if is_instance_valid(arena_gate):
		var alive:bool=is_instance_valid(overseer) and not overseer._dead
		arena_gate.update_encounter(player.global_position.x,player._dying,alive,alive and overseer.active)
	if not player._dying and player.is_on_floor() and _valid_cache_position(player.global_position):
		_last_grounded=player.global_position

func on_player_death() -> void:
	# The nearest robot reports the kill.
	if is_instance_valid(voice):
		var nearest:Node3D=null;var best:=8.0
		for foe in get_tree().get_nodes_in_group("enemies"):
			if foe.get("_dead")==false and absf(foe.global_position.x-player.global_position.x)<best:nearest=foe;best=absf(foe.global_position.x-player.global_position.x)
		if nearest:voice.say(nearest,"neutralized",true)
	if is_instance_valid(arena_gate):arena_gate.release()
	if is_instance_valid(overseer):overseer.reset_encounter()
	# Farming v0.2: collected currency/components and pending rewards survive death.
	# Legacy caches remain reclaimable, but new deaths never replace or destroy them.
	_save_progress()
	if save_error:_message(TEXT.t("msg_death_save_failed"),5.0,3)
	else:_message(TEXT.t("msg_death_kept"),4.0,2)

func _refresh_cache_marker() -> void:
	if not is_instance_valid(_cache_marker):return
	_cache_marker.position=death_cache.position()
	_cache_marker.show_amount(death_cache.amount())

func reclaim_shards() -> bool:
	if player._dying or not death_cache.is_active() or reach_distance(death_cache.position())>=1.3:return false
	var recovered:int=death_cache.take()
	shards=mini(999999,shards+recovered)
	_refresh_cache_marker()
	_save_progress()
	_message(TEXT.t("msg_shards_recovered")%recovered,3.0,2)
	return true

# G02 owner API. UI may only request a selection; ledger validates ownership/slot.
func apply_equipment_selection(slot: String, id: String) -> bool:
	if player._dying or player._attack_phase>0 or player._dash_left>0 or player.guard.is_guarding():return false
	if not equipment.equip(slot,id):return false
	player.equip_weapon(equipment.equipped_weapon())
	player.set_arm_servo(equipment.prefixes.installed("reinforced_arm")=="servo_i")
	shield=equipment.equipped("shield")=="salvage_shield"
	player.shield_unlocked=shield
	player._release_guard()
	player.shield_visual.visible=shield
	armor=equipment.equipped("armor")=="lab_armor"
	if armor:_equip_armor(false)
	else:
		player.max_hp=5
		for side in ["Left","Right"]:
			var socket=player._hero_skel.get_node_or_null("ArmorSocket"+side)
			if socket:socket.hide()
	player.hp=mini(player.hp,player.max_hp)
	_save_progress()
	return true

func equipment_state(message: String="") -> Dictionary:
	var state:Dictionary=equipment.export_state()
	var result:Dictionary={"shards":shards,"owned":state.owned,"equipped":{"weapon":equipment.equipped("weapon"),"armor":equipment.equipped("armor"),"shield":equipment.equipped("shield")}}
	if not message.is_empty():result.feedback=message
	return result

func _farming_objective() -> String:
	if player.global_position.x>12.5 or not equipment.owns("reinforced_arm") or not "first" in cleared:return ""
	if servo_run.run_id>0 and not servo_run.can_begin():
		var count:int=servo_run.defeated_count()
		if count<4:return TEXT.t("objective_servo_progress")%count
		if count==4:
			if servo_run.specialist_servo==0:return TEXT.t("objective_servo_bearer")
			return TEXT.t("objective_servo_taken") if servo_run.servo_collected else TEXT.t("objective_servo_exposed")
		var nearest:=Vector3.ZERO;var distance:=INF
		for group in 6:
			if servo_run.pending(servo_run.run_id,group).is_empty():continue
			var at:Vector3=servo_run.reward_position(group)
			if absf(at.x-player.global_position.x)<distance:
				distance=absf(at.x-player.global_position.x);nearest=at
		return TEXT.t("objective_servo_collect")%("←" if nearest.x<player.global_position.x else "→")
	if not equipment.prefixes.owns_module("servo_i"):
		if shards>=12 and equipment.prefixes.servo>=2:return TEXT.t("objective_servo_craft")
		return TEXT.t("objective_servo_optional")
	if equipment.prefixes.installed("reinforced_arm")!="servo_i":return TEXT.t("objective_servo_install")
	return ""

func _mission_objective() -> String:
	if player.global_position.x>=17 and player.global_position.x<29 and is_instance_valid(power_sector) and power_sector.defeated.size()<3:return TEXT.t("objective_power_sector")
	var farming:=_farming_objective()
	if not farming.is_empty():return farming
	if not equipment.owns("robot_arm"): return TEXT.t("objective_take_arm")
	if gate_open:return TEXT.t("objective_reach_exit")
	if not "first" in cleared:return TEXT.t("objective_first_guard")
	if player.global_position.x<12.5 and not equipment.owns("reinforced_arm"):
		if pending_shards.has(FIRST_SALVAGE_ID):return TEXT.t("objective_salvage_guard")
		if not "entry_supply" in broken_crates and shards<6:return TEXT.t("objective_break_crate")
		if pending_shards.has("entry_supply"):return TEXT.t("objective_collect_crate")
		if shards>=6:return TEXT.t("objective_upgrade_arm")
	if player.global_position.x<29:
		if not equipment.owns("salvage_shield"):return TEXT.t("objective_take_shield")
		if not checkpoint:return TEXT.t("objective_checkpoint")
		if not equipment.owns("reinforced_arm") and shards>=int(equipment.CATALOGUE["reinforced_arm"].cost):return TEXT.t("objective_arm_available")%int(equipment.CATALOGUE["reinforced_arm"].cost)
	if not "duelist" in cleared:return TEXT.t("objective_duelist")
	if not "guard" in cleared:return TEXT.t("objective_cooling")
	if not "freight_raider" in cleared or not "freight_duelist" in cleared:return TEXT.t("objective_freight")
	if not "relay_guard" in cleared:return TEXT.t("objective_relay")
	return TEXT.t("objective_overseer")

func _build_freight_rooms() -> void:
	relay_console=preload("res://modules/world/checkpoint_console.gd").new()
	relay_console.name="RelayCheckpoint";relay_console.position=ROUTE.RELAY_CONSOLE_POS
	relay_console.set_saved(relay_checkpoint);add_child(relay_console)
	# Sightline breaks, no extra combat locks.
	for x in ROUTE.FREIGHT_COVER_XS:
		var cover=_box("FreightCover",Vector3(x,.45,0),Vector3(1.0,.9,.65),Color(.15,.22,.24),true)
		cover.get_child(0).hide()
		var skin=preload("res://assets3d/env/factory_crate_v1/model.glb").instantiate()
		skin.name="FreightCoverSkin";skin.position.y=-.45+.43
		skin.scale=Vector3(.5,.55,.4);cover.add_child(skin)  # one big case: 0.95 x 0.85 x 0.62 m

func can_collect_start_arm() -> bool:
	if not arm_pickup or not arm_pickup.can_reach(player.global_position): return false
	if player._dying or player._attack_phase > 0 or player._dash_left > 0: return false
	return not equipment.owns("robot_arm")

func collect_start_arm() -> bool:
	if not can_collect_start_arm(): return false
	equipment.grant("robot_arm")
	equipment.equip_weapon("robot_arm")
	player.equip_weapon("robot_arm")
	arm_pickup.set_collected(true)
	_save_progress()
	_message(TEXT.t("msg_arm_equipped"), 6.0, 2)
	if save_error: _message(TEXT.t("msg_arm_save_failed"), 6.0, 3)
	# The guard of the first room storms in the moment he is armed.
	if is_instance_valid(alarm) and alarm.running:
		for foe in enemies:
			if is_instance_valid(foe) and foe.encounter_id=="first" and not foe._dead:foe.provoke()
	return true
