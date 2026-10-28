extends "res://enemy.gd"
## Sentinel (Meshy model, asset_library/meshy/2026-10-23_atlas; a more distinct redesign is
## planned): it waits motionless in a dark wall alcove with its head ring
## off. When Rend runs past - or strikes it, or comes right up to it - the ring flickers on,
## it looks up and steps out onto the floor strip, then fights like a duelist. Walking or
## sneaking past leaves it asleep. Its ring turns red while it winds up a strike.

const MODEL := "res://assets3d/characters/sentinel_v1/model.glb"
const WAKE_RANGE := 2.6       # |dx| at which a running Rend wakes it
const WAKE_SPEED := 3.6       # Rend's ground speed that counts as running
const ALERT_TIME := 1.1       # s looking up before it moves
const STEP_OUT_SPEED := 1.6   # m/s out of the alcove
const LANE_Z := -0.7          # where it joins the floor strip (its back edge)
const NEAR_WAKE := 1.6        # floor distance at which even a sneaking Rend wakes it
const RING_IDLE := Color(0.35, 0.9, 1.0)
const RING_STRIKE := Color(1.0, 0.18, 0.08)

enum { ASLEEP, WAKING, STEPPING, AWAKE }
var sentinel := ASLEEP
var _sentinel_t := 0.0
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _ring_light: OmniLight3D
var _ring_level := 0.0

func _ready() -> void:
	role = 1
	super._ready()
	hp = 4;speed = 4.3
	if has_node("RoleLabel"):$RoleLabel.text = "SENTINEL"
	set_physics_process(true)

func _try_load_chaser() -> void:
	_mechanical = true
	_chaser = load(MODEL).instantiate()
	$VisualPivot.add_child(_chaser)
	$VisualPivot.scale = Vector3.ONE
	_chaser.rotation.y = PI / 2  # model front (+Z) along +X like the other robots
	visual.visible = false
	_skeleton = _chaser.find_child("Skeleton3D", true, false) as Skeleton3D
	_anim = _chaser.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_body_mesh = _chaser.find_child("char1", true, false) as MeshInstance3D
	if _anim:
		var locomotion := AnimationLibrary.new()
		locomotion.add_animation("walk", preload("res://generated/sentinel_walk.tres").get_animation("walk"))
		locomotion.add_animation("run", preload("res://generated/sentinel_run.tres").get_animation("run"))
		if _anim.has_animation_library(""):_anim.remove_animation_library("")
		_anim.add_animation_library("", locomotion)
		_anim.add_animation_library("combat", preload("res://generated/sentinel_combat.tres"))
		_anim.add_animation_library("react", preload("res://generated/sentinel_react.tres"))
		_anim.add_animation_library("strikes", preload("res://generated/sentinel_strikes.tres"))
		_anim.play("combat/dormant")
	if _skeleton:
		_stance = preload("res://crouch_pose.gd").new()
		_stance.actor = self
		_skeleton.add_child(_stance)
		_hit_overlay = preload("res://modules/combat/hit_overlay.gd").new()
		_hit_overlay.arm_weight = 0.8
		_skeleton.add_child(_hit_overlay)
		_hit_physics = preload("res://modules/combat/hit_physics.gd").new()
		_hit_physics.actor = self
		_skeleton.add_child(_hit_physics)
		_build_ring.call_deferred()

func _attach_weapon() -> void:
	pass  # fists

# The head is a disc; the ring sits on its front rim and lights the alcove around it.
func _build_ring() -> void:
	var head := _skeleton.find_bone("Head")
	if head < 0:return
	var mount := BoneAttachment3D.new();mount.bone_name = "Head";_skeleton.add_child(mount)
	_ring = MeshInstance3D.new();_ring.name = "HeadRing"
	var torus := TorusMesh.new();torus.inner_radius = 0.105;torus.outer_radius = 0.125
	torus.rings = 48;torus.ring_segments = 8;_ring.mesh = torus
	_ring_mat = StandardMaterial3D.new();_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.albedo_color = Color(0.08, 0.09, 0.1);_ring_mat.emission_enabled = true
	_ring_mat.emission = RING_IDLE;_ring_mat.emission_energy_multiplier = 0.0
	_ring.material_override = _ring_mat;_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mount.add_child(_ring)
	_ring_light = OmniLight3D.new();_ring_light.light_color = RING_IDLE;_ring_light.light_energy = 0.0
	_ring_light.omni_range = 2.2;_ring_light.shadow_enabled = false;mount.add_child(_ring_light)
	await get_tree().process_frame
	# Place in world metres from the head bone: disc centre ~12 cm up, ring on its face.
	var head_pose: Transform3D = _skeleton.global_transform * _skeleton.get_bone_global_pose(head)
	var forward := _chaser.global_basis.z.normalized()
	_ring.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, forward)), head_pose.origin + Vector3.UP * 0.12 + forward * 0.075)
	_ring_light.global_position = head_pose.origin + Vector3.UP * 0.12 + forward * 0.3

func _set_ring(level: float, color: Color) -> void:
	_ring_level = level
	if _ring_mat:
		_ring_mat.emission = color;_ring_mat.emission_energy_multiplier = level * 6.0
		_ring_mat.albedo_color = color.darkened(0.2) if level > 0.05 else Color(0.08, 0.09, 0.1)
	if _ring_light:_ring_light.light_color = color;_ring_light.light_energy = level * 1.6

# Fists only: its own punch combination and elbow, never the blade strikes.
func _fights_unarmed() -> bool:
	return true

func _choose_strike() -> String:
	if forced_strike in STRIKES:return forced_strike
	return "elbow" if _strike == "punch" else "punch"

## A radio call or a camera wakes it the proper way (look up, step out), not straight into a chase.
func provoke() -> void:
	if sentinel == ASLEEP:wake()
	elif sentinel == AWAKE:super.provoke()

func wake() -> void:
	if sentinel != ASLEEP:return
	sentinel = WAKING;_sentinel_t = 0.0
	if _anim:_anim.play("combat/alert", 0.2)
	var voice := get_tree().get_first_node_in_group("robot_voice")
	if voice:voice.say(self, "intruder", true)
	FX.play("block", 0.6, -6.0)

func take_melee_hit(damage: int, knockback: Vector3) -> void:
	if sentinel != AWAKE:
		# Struck while asleep: it wakes at once and steps out.
		sentinel = STEPPING;_sentinel_t = 0.0;_set_ring(1.0, RING_IDLE)
	super.take_melee_hit(damage, knockback)

func _physics_process(delta: float) -> void:
	if _dead or sentinel == AWAKE:
		super._physics_process(delta)
		if not _dead:_set_ring(1.0, RING_STRIKE if _state in [WINDUP, SWING] else RING_IDLE)
		return
	_sentinel_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	match sentinel:
		ASLEEP:
			_set_ring(0.0, RING_IDLE)
			if player and not player._dying:
				var dx := absf(player.global_position.x - global_position.x)
				var near := Vector2(dx, player.global_position.z - global_position.z).length()
				var running: bool = player.has_method("ground_speed") and player.ground_speed() > WAKE_SPEED
				if (dx < WAKE_RANGE and running) or near < NEAR_WAKE:wake()
		WAKING:
			# The ring flickers on, then holds.
			var on := _sentinel_t > 0.5 or fmod(_sentinel_t, 0.12) < 0.06
			_set_ring(clampf(_sentinel_t / 0.5, 0.2, 1.0) if on else 0.05, RING_IDLE)
			if player:$VisualPivot.rotation.y = lerp_angle($VisualPivot.rotation.y, PI if player.global_position.x < global_position.x else 0.0, 3.0 * delta)
			if _sentinel_t >= ALERT_TIME:
				sentinel = STEPPING;_sentinel_t = 0.0
				if _anim:_anim.play("walk", 0.15)
		STEPPING:
			_set_ring(1.0, RING_IDLE)
			# Out of the alcove onto the strip, facing the way it walks, then turn to Rend.
			velocity = Vector3(0, velocity.y + get_gravity().y * delta, STEP_OUT_SPEED)
			$VisualPivot.rotation.y = lerp_angle($VisualPivot.rotation.y, -PI / 2, 6.0 * delta)
			move_and_slide()
			# Joins the fight on the strip's back edge, or wherever a prop stops it.
			if global_position.z >= LANE_Z or (is_on_wall() and global_position.z > -1.3):
				global_position.z = LANE_Z;velocity = Vector3.ZERO
				sentinel = AWAKE;_enter(CHASE)
