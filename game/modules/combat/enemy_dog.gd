extends "res://enemy.gd"
## Unitree-class robot dog: sprints in and alternates two attacks. The bite: it crouches
## briefly and pounces low (jump over it or dodge; ducking does not help). The arm swipe: the
## manipulator on its back (Blender, tools/blender/build_dog_arm.py) cocks back with its
## amber sensor flaring and whips across at chest height (duck under it or dodge).
## The back plate carries a weapon rail ("WeaponMount") for the armed dogs later on.
## Model: Hermes P3 enemy_dog_kessel_v2, rigged by tools/blender/rig_quadruped.py.
const MODEL := "res://assets3d/characters/robot_dog_v1/model.glb"
const LUNGE_WINDUP := 0.35  # crouch phase of the lunge clip (seconds into "lunge")
const LUNGE_LENGTH := 0.7
# Flinch: the whole body jerks nose-up and rolls away from the blow, then springs back.
var _pitch := [0.0, 0.0]  # [angle, velocity]
var _roll := [0.0, 0.0]
const FLINCH_STIFFNESS := 14.0
const FLINCH_DAMPING := 0.55
const ARM_MODEL := preload("res://assets3d/characters/dog_arm_v1/model.glb")
const ARM_BACK := Vector3(0, 0.1, -0.06)    # back plate, above the Body bone (model space)
# Arm joint angles (rad, + leans toward the dog's front): [shoulder, elbow, claw].
const ARM_REST := [-0.55, 2.3, 0.6]        # folded over its back like a scorpion tail
const ARM_COCKED := [-1.05, 2.6, 1.0]
const ARM_STRUCK := [1.05, 0.25, 0.1]      # whipped forward, reaching at chest height
var _arm: Node3D
var _arm_joints := {}
var _arm_angles := [-0.55, 2.3, 0.6]
var _arm_light: OmniLight3D

func _ready() -> void:
	super._ready()
	speed = 5.2
	# A low, long body: the hurtbox matches it so Rend's arm and the floor strip line up.
	var cs := $Collision as CollisionShape3D
	cs.shape.size = Vector3(1.0, 0.95, 0.6)
	cs.position.y = 0.475

func _try_load_chaser() -> void:
	_mechanical = true
	_chaser = load(MODEL).instantiate()
	$VisualPivot.add_child(_chaser)
	$VisualPivot.scale = Vector3.ONE
	_chaser.rotation.y = PI / 2  # head along +X like the other robots
	visual.visible = false
	_skeleton = _chaser.find_child("Skeleton3D", true, false) as Skeleton3D
	_anim = _chaser.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for clip in ["idle", "trot", "run"]:
			if _anim.has_animation(clip):_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		# The shared state machine names humanoid clips; alias the dog's own.
		var combat := AnimationLibrary.new()
		for pair in [["idle", "idle"], ["slash_light", "lunge"], ["hit_react", "hit"]]:
			combat.add_animation(pair[0], _anim.get_animation(pair[1]))
		_anim.add_animation_library("combat", combat)
		_anim.play("idle")
	_mount_arm()

# The arm rides the Body bone, so it bobs and flinches with the trot.
func _mount_arm() -> void:
	if not is_instance_valid(_skeleton):return
	var bone := _skeleton.find_bone("Body")
	if bone < 0:return
	var attach := BoneAttachment3D.new();attach.bone_name = "Body";_skeleton.add_child(attach)
	_arm = ARM_MODEL.instantiate();attach.add_child(_arm)
	# Place it on the back in model space, whatever the bone's own orientation.
	var rest := _skeleton.get_bone_global_rest(bone)
	_arm.transform = rest.affine_inverse() * Transform3D(Basis.IDENTITY, rest.origin + ARM_BACK)
	for joint in ["DogArmShoulder", "DogArmElbow", "DogArmClaw", "DogArmFingerL", "DogArmFingerR"]:
		_arm_joints[joint] = _arm.find_child(joint, true, false)
	_arm_light = OmniLight3D.new();_arm_light.light_color = Color(1, .5, .12);_arm_light.omni_range = 0.8
	_arm_light.light_energy = 0.0;_arm_light.shadow_enabled = false
	var claw: Node3D = _arm_joints.get("DogArmClaw")
	if claw:claw.add_child(_arm_light);_arm_light.position = Vector3(0, 0.06, 0.04)

func _attach_weapon() -> void:
	pass  # the bite is the weapon

# Bite, swipe, bite, swipe... (the first attack is the bite). Without the arm only bites.
func _next_attack_is_low() -> bool:
	return _attack_count % 2 == 1 or not is_instance_valid(_arm)

# The pounce carries the jaws well beyond a humanoid's arm; the arm reaches less far.
func _weapon_reach() -> float:
	return 2.3 if _committed_low else 1.7

# The pounce and the arm both sweep across: it strikes from a wider depth offset.
func _strike_depth() -> float:
	return 0.6

func _windup_duration() -> float:
	return 0.5 if _committed_low else 0.48

func _recovery_duration() -> float:
	return 0.55

func _reaction_clip(_heavy: bool, _shocked: bool) -> String:
	return "hit"

func take_melee_hit(damage: int, knockback: Vector3) -> void:
	var was_dead := _dead
	super.take_melee_hit(damage, knockback)
	if was_dead or _dead:return
	var heavy := damage >= 2 or knockback.y > 2.5
	# Struck from the front the nose snaps up; the body rolls away from the blow.
	var from_front := signf(knockback.x) != _front_sign()
	_pitch[1] += (6.5 if heavy else 4.5) * (1.0 if from_front else -0.6)
	_roll[1] += (3.5 if heavy else 2.4) * (1.0 if randf() < 0.5 else -1.0)

func _process(delta: float) -> void:
	if _dead:return
	for spring in [_pitch, _roll]:
		var accel: float = -FLINCH_STIFFNESS * FLINCH_STIFFNESS * spring[0] - 2.0 * FLINCH_DAMPING * FLINCH_STIFFNESS * spring[1]
		spring[1] += accel * delta;spring[0] += spring[1] * delta
	if is_instance_valid(_chaser):
		_chaser.rotation = Vector3(-_pitch[0] * 0.35, PI / 2, _roll[0] * 0.5)  # model forward is its local Z
	_update_arm(delta)

func _update_arm(delta: float) -> void:
	if not is_instance_valid(_arm) or _arm_joints.is_empty():return
	var swipe := not _committed_low and _state in [WINDUP, SWING, RECOVERY] and not _hit_recovering
	var goal: Array = ARM_REST
	var rate := 6.0
	if swipe and _state == WINDUP:goal = ARM_COCKED;rate = 10.0
	elif swipe and _state == SWING:goal = ARM_STRUCK;rate = 30.0
	elif swipe and _state == RECOVERY:goal = ARM_STRUCK if _state_t < 0.12 else ARM_REST;rate = 5.0
	else:
		# Idle sway while it closes in.
		var t := Time.get_ticks_msec() * 0.001
		goal = [ARM_REST[0] + sin(t * 1.7) * 0.06, ARM_REST[1] + sin(t * 2.3) * 0.08, ARM_REST[2]]
	for i in 3:_arm_angles[i] = lerpf(_arm_angles[i], goal[i], minf(1.0, rate * delta))
	_arm_joints.DogArmShoulder.rotation.x = _arm_angles[0]
	_arm_joints.DogArmElbow.rotation.x = _arm_angles[1]
	_arm_joints.DogArmClaw.rotation.x = _arm_angles[2]
	var open := 0.5 if swipe and _state == WINDUP else 0.12
	for side in [["DogArmFingerL", 1.0], ["DogArmFingerR", -1.0]]:
		var finger: Node3D = _arm_joints[side[0]]
		if finger:finger.rotation.z = lerpf(finger.rotation.z, open * side[1], minf(1.0, 12.0 * delta))
	# The sensor flares as it cocks back: the read for "duck now".
	_arm_light.light_energy = lerpf(_arm_light.light_energy, 2.5 if swipe and _state == WINDUP else 0.0, minf(1.0, 14.0 * delta))

func _update_weapon_pose(_delta: float) -> void:
	if not _anim or _dead:return
	if _hit_recovering or _stun > 0:
		if _anim.current_animation != "hit" and not _anim.is_playing():_anim.play("idle", 0.1)
		return
	if not _committed_low and _state in [WINDUP, SWING, RECOVERY]:
		# The swipe is the arm's work: the dog plants its feet (the lunge's opening stance),
		# sinking a little into a brace as the arm cocks back.
		if _anim.assigned_animation != "lunge":_anim.play("lunge", 0.08)
		_anim.speed_scale = 0.0
		var brace := clampf(_state_t / _windup_duration(), 0, 1) if _state == WINDUP else 0.0
		_anim.seek(LUNGE_WINDUP * 0.15 * brace, true);_anim.advance(0)
		return
	match _state:
		WINDUP, SWING, RECOVERY:
			# Crouch through the windup, pounce in the swing, settle in recovery.
			var t := 0.0
			if _state == WINDUP:t = lerpf(0.0, LUNGE_WINDUP, clampf(_state_t / _windup_duration(), 0, 1))
			elif _state == SWING:t = lerpf(LUNGE_WINDUP, 0.5, clampf(_state_t / SWING_S, 0, 1))
			else:t = lerpf(0.5, LUNGE_LENGTH, clampf(_state_t / _recovery_duration(), 0, 1))
			if _anim.assigned_animation != "lunge":_anim.play("lunge", 0.05)
			_anim.speed_scale = 0.0
			_anim.seek(t, true);_anim.advance(0)
		_:
			# Real motion, not the wish: blocked, it stands instead of trotting on the spot.
			var ground := Vector2(get_real_velocity().x, get_real_velocity().z).length()
			var moving := ground > 0.3
			var clip := ("run" if ground > 3.0 else "trot") if moving else "idle"
			if _anim.current_animation != clip:_anim.play(clip, 0.12)
			_anim.speed_scale = 1.0

func _die(knockback := Vector3.ZERO) -> void:
	super._die(knockback)
	_tear_off_arm(knockback)
	if is_instance_valid(_chaser):_chaser.rotation = Vector3(0, PI / 2, 0)
	_start_dog_ragdoll.call_deferred(knockback)

# The killing blow throws the body; legs fold under it (quadruped_death.gd). The authored
# collapse clip stays as the fallback.
func _start_dog_ragdoll(impulse: Vector3) -> void:
	if not is_instance_valid(_skeleton) or is_instance_valid(_death_physics):return
	var ragdoll := preload("res://modules/combat/quadruped_death.gd").new()
	_skeleton.add_child(ragdoll)
	if ragdoll.build(self, impulse):
		_death_physics = ragdoll
		if _anim:_anim.pause()
		$Collision.disabled = true
		velocity = Vector3.ZERO
		return
	ragdoll.queue_free()
	if _anim and _anim.has_animation("death"):
		_anim.speed_scale = 1.0
		_anim.play("death", 0.05)

# The arm snaps off its mount and clatters away (robots fall apart).
func _tear_off_arm(knockback: Vector3) -> void:
	if not is_instance_valid(_arm):return
	var at := _arm.global_transform
	var body := RigidBody3D.new();body.collision_layer = 0;body.collision_mask = 1;body.mass = 3.0
	var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = Vector3(0.12, 0.5, 0.12)
	shape.shape = box;shape.position = Vector3(0, 0.3, 0);body.add_child(shape)
	get_tree().current_scene.add_child(body);body.global_transform = at
	_arm.get_parent().remove_child(_arm);body.add_child(_arm);_arm.transform = Transform3D.IDENTITY
	body.linear_velocity = Vector3(signf(knockback.x) * 2.5, 3.5, randf_range(-0.6, 0.6))
	body.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-3, 3), randf_range(-8, 8))
	FX.metal_contact(at.origin, Vector3.UP)
	_arm = null
	var tw := body.create_tween();tw.tween_interval(9.0);tw.tween_property(body, "scale", Vector3.ONE * 0.01, 0.6);tw.tween_callback(body.queue_free)
