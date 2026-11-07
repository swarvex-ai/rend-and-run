extends Node3D
## Prototype-Hauptebene: seitliche Follow-Kamera mit Screenshake, Respawn, HP-HUD.

# 35-degree lens pulled back to preserve the previous playable-plane framing.
# Background machinery reads at the intended scale instead of shrinking into the bay.
@export var follow_offset := Vector3(0.0, 1.05, 9.57596096)
@export var follow_speed := 9.0
@export var first_room_closeup := true
# Beat-'em-up framing: the camera looks down slightly so depth on the floor strip reads,
# and follows Rend's depth only partially so the floor does not slide with him.
@export var camera_pitch_deg := 9.0
@export var depth_follow := 0.3

@onready var player: CharacterBody3D = $Player
@onready var spawn_point := Vector3(0, 1.2, 0)

var pause_controller:Node
var route: Node3D
var _spawned := 0
var attack_cadence = preload("res://modules/combat/attack_cadence.gd").new()
var wave := 1
var wave_wait := 0.0
var _respawning := false

func _ready() -> void:
	process_physics_priority = -100 # Advance once before enemy decisions; pauses with scene.
	pause_controller=preload("res://pause_controller.gd").new()
	add_child(pause_controller)
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	route=preload("res://lab_route.gd").new()
	add_child(route)
	$Camera3D.rotation.x = -deg_to_rad(camera_pitch_deg)
	if OS.get_environment("V50_TEST")=="1":
		var runner:=preload("res://tests/pulse_pack_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V49_TEST")=="1":
		var runner:=preload("res://tests/projectile_lifetime_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V48_TEST")=="1":
		var runner:=preload("res://tests/guard_spacing_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V47_TEST")=="1":
		var runner:=preload("res://tests/coolant_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V46_TEST")=="1":
		var runner:=preload("res://tests/edge_warning_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V45_TEST")=="1":
		var runner:=preload("res://tests/security_pair_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V44_TEST")=="1":
		var runner:=preload("res://tests/duelist_footwork_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V41_TEST")=="1":
		var runner:=preload("res://tests/attack_cue_integration.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V35_TEST")=="1":
		var runner:=preload("res://tests/checkpoint_feedback_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V33_TEST")=="1":
		var runner:=preload("res://tests/movement_audio_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V31_TEST")=="1":
		var runner:=preload("res://tests/finisher_fallback_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V30_TEST")=="1" and not get_tree().root.has_meta("complete_test_started"):
		get_tree().root.set_meta("complete_test_started",true)
		var runner:=preload("res://tests/completion_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	if OS.get_environment("V28_TEST")=="1" and not get_tree().root.has_meta("pause_test_started"):
		get_tree().root.set_meta("pause_test_started",true)
		var runner:=preload("res://tests/pause_integration_test.gd").new()
		add_child(runner);runner.call_deferred("run")
	# Roles must exist before ready: initial nodes use exported values in the scene.
	for e in get_tree().get_nodes_in_group("enemies"):
		e._spawn_x = e.position.x

func _physics_process(delta: float) -> void:
	attack_cadence.advance(delta)

func claim_enemy_attack(origin_x: float) -> bool:
	return attack_cadence.try_claim(origin_x)

@onready var _fps := 0

func _process(delta: float) -> void:
	_fps = int(1.0 / maxf(delta, 0.0001))
	var cam := $Camera3D
	# Frame the authored first encounter at character scale, then ease back to
	# the established traversal view before the taller maintenance platforms.
	var room_weight := 1.0-smoothstep(11.5,16.5,player.global_position.x) if first_room_closeup and is_instance_valid(route) else 0.0
	var view_offset := follow_offset
	view_offset.z=lerpf(follow_offset.z,7.2,room_weight)
	var look_ahead := lerpf(.8,1.3,room_weight)
	# Raise the camera by its pitch so the playable plane stays at the same screen height.
	view_offset.y += tan(deg_to_rad(camera_pitch_deg)) * view_offset.z
	var target := player.global_position + view_offset + Vector3(player.facing * look_ahead,0,0)
	target.z -= player.global_position.z * (1.0 - depth_follow)
	cam.global_position = cam.global_position.lerp(target, 1.0 - exp(-follow_speed * delta))
	if FX.shake > 0.0:
		var s := FX.shake * FX.shake * 0.35
		cam.position += Vector3(randf_range(-s, s), randf_range(-s, s), 0)
	if Input.is_action_just_pressed("restart"):
		pause_controller.request_restart()
	if player.global_position.y < -8.0 and not player._dying:
		_on_player_died()

func _on_player_died() -> void:
	if _respawning:return
	_respawning=true
	if is_instance_valid(route):route.on_player_death()
	FX.hitstop(0.25, 0.02)
	FX.add_shake(1.0)
	FX.blood(player.global_position + Vector3.UP, 40, 4.5)
	player.play_death_anim()
	# Long enough to watch him collapse (ragdoll, like the robots) before the respawn.
	await get_tree().create_timer(2.4, false, false, true).timeout
	player.hp = player.max_hp
	player.reset_state()  # drops the ragdoll before he is moved
	player.global_position = spawn_point
	player._update_locomotion(true)
	_respawning=false

func _make_enemy(at_x: float, enemy_role := 0, enemy_script: Script = null, gun := "", with_shield := false) -> CharacterBody3D:
	# Frischer Chaser mit derselben Node-Struktur wie in main.tscn,
	# damit _ready() (Shape-Skalierung, Waffen-Socket) korrekt laeuft.
	var e := CharacterBody3D.new()
	e.set_script(enemy_script if enemy_script != null else load("res://enemy.gd"))
	e.role = enemy_role
	e.gun_kind = gun
	e.shield = with_shield
	e.add_to_group("enemies")
	var col := CollisionShape3D.new()
	col.name = "Collision"
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.7, 0.9, 0.7)
	col.shape = bs
	col.position = Vector3(0, 0.45, 0)
	e.add_child(col)
	var pivot := Node3D.new()
	pivot.name = "VisualPivot"
	var vis := MeshInstance3D.new()
	vis.name = "Visual"
	vis.position = Vector3(0, 0.45, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.9, 0.7)
	vis.mesh = bm
	pivot.add_child(vis)
	e.add_child(pivot)
	# Deterministic depth lane and sway phase from spawn order (instance ids shift with load order).
	_spawned += 1
	e._lane_offset = float(_spawned % 3 - 1) * 0.25
	e._spawn_index = _spawned
	# (_spawned + 5) % 7 keeps the first route encounter (third spawn) at its scripted
	# phase 1 while spreading the other robots across the 0-6 phases.
	e._sway_phase = float((_spawned + 5) % 7)
	add_child(e)                      # _ready(): Kollision 1.5 m, Modell + Waffe
	e.global_position = Vector3(at_x, 0.05, 0)
	return e
