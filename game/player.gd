extends CharacterBody3D
const ARM_PREFIX := preload("res://modules/equipment/prefix_ledger.gd")
const UI_TEXT = preload("res://data/ui_texts.gd")
## Spieler für Rend&Run — Laufen, Hüpfen mit Gewicht + Arm-Nahkampf (P04, hero_v05).
## Gamepad primär (Stick/D-Pad + Cross + Square), Tastatur (A/D, Pfeile, Space, J/X) gleichwertig.
## V10: Same cutting motion, shorter anticipation/recovery, mobile attacks and defense.

signal died
signal guard_contact(outcome: String)
var shield_unlocked := false
var shield_kind := "salvage"            # "salvage" chest plate or "riot" shield (shield_visual.gd)
var weapon_id := ""
var _sword_model: Node3D
var _starter_model: Node3D
var _heavy_model: Node3D
var _servo_model: Node3D
var _servo_installed := false
var _attack_recovery_factor := 1.0
var _blade_contact = preload("res://modules/combat/blade_contact.gd").new()
var _blade_hand := -1
var _crouched_blade_pose := Transform3D.IDENTITY
var _crouched_blade_valid := false
var _slash_trail: Node3D
var guard = preload("res://modules/combat/guard_state.gd").new()
var _guard_require_release := false
var shield_visual: Node3D

@export var move_speed := 7.5
@export var acceleration := 90.0
@export var friction := 90.0
@export var jump_velocity := 6.4
@export var gravity_mult := 1.4          # schwerer als Standard = saftiger
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12
@export var fast_fall_mult := 1.8        # Scheitelpunkt fällt schneller
@export var max_hp := 5
# Beat-'em-up floor strip: Rend walks into and out of the scene between these depths.
@export var depth_min := -1.05
@export var depth_max := 1.25
@export var depth_speed_factor := 0.7

var facing := 1.0
var hp := max_hp
var _coyote := 0.0
var _jump_buffer := 0.0
var _was_on_floor := true
var _step_distance := 0.0
var _step_side := false
var _foot_contacts=preload("res://modules/audio/foot_contact_clock.gd").new()
var _squash_tween: Tween
var _iframes := 0.0
var _attack_phase := 0                  # 0=none 1=startup 2=active 3=recovery
var _attack_timer := 0.0
var _attack_dur := 0.0
var _startup_dur := 0.0
var _active_dur := 0.0
var _combo_fire_at := 0.0               # Combo-Zuendung: erst nach dem light-Trefferfenster
var _combo_pending := false             # zweiter Druck innerhalb des Pufferfensters
var _attack_key_was := false            # Flankenerkennung: Key-Echo (Halten) zaehlt nicht
var _attack_elapsed := 0.0              # Clip-Zeit (skaliert — hitstop-treu wie die Animation)
var _seq := 0                           # 1=slash_light 3=slash_combo_2
var _hit_ids := {}                      # Ziel-InstanceID -> true: EIN Treffer pro Ziel pro Hieb

const COMBO_BUFFER_S := 0.54            # generous second-press window

@onready var visual: MeshInstance3D = $VisualPivot/Visual
@onready var pivot: Node3D = $VisualPivot
@onready var arm: Node3D = $VisualPivot/Arm
@onready var blade: MeshInstance3D = $VisualPivot/Arm/Blade
@onready var hit_pivot: Node3D = $HitPivot

# --- Helden-Asset (hero_v05-Release, P03-Inport) ---
var _hero: Node3D
var _hero_anim: AnimationPlayer
var _hero_skel: Skeleton3D
var _crouch_modifier: SkeletonModifier3D
var _anim_state := ""
var _land_lock := 0.0
var _hit_lock := 0.0
var _last_hit_dir := 0.0
var _hit_overlay: SkeletonModifier3D   # upper-body mocap hit reaction (hit_overlay.gd)
var _death_physics: SkeletonModifier3D # ragdoll after death (articulated_death.gd, same as the robots)
var _hit_physics: SkeletonModifier3D   # physical hit reaction: upper body thrown, then caught (hit_physics.gd)
var carried: RigidBody3D = null        # supply case in Rend's hands (throwable_crate.gd)
const ATTACK_TEMPO := 1.15
var gun: Node3D = null                 # the drawn firearm (gun.gd), when slot 3 or 4 is active
# Weapon slots (keys 1-4, mouse wheel, pad Back): 1 hands free, 2 the robot arm (melee),
# 3 a sidearm (pistol, SMG), 4 a long gun (scatter gun, energy rifle). Attack uses the drawn
# weapon. Guns taken from robots fill slot 3 or 4; a new one replaces the old (dropped).
const SLOT_FREE := 1
const SLOT_MELEE := 2
const SLOT_SIDEARM := 3
const SLOT_LONG := 4
const SIDEARMS := ["pistol", "smg"]
var slot := SLOT_MELEE
var holstered := {}                    # slot -> {kind, ammo (magazine), reserve} for the guns he carries
var gun_mods := {}                     # gun kind -> Array of gun.gd MODS keys (weapon bench, saved)
signal slot_changed(slot: int)
var _aim_t := 0.0                      # > 0 while he holds the shooting pose
var _gun_hold: SkeletonModifier3D      # gun_hold_pose.gd: shoulder the gun, hands on its grips
var _shot_pending := false

# The shot leaves the muzzle where the gun is drawn this very frame, along its barrel.
func _fire_pending_shot() -> void:
	if not _shot_pending:return
	_shot_pending = false
	if is_instance_valid(gun):gun.fire(gun.global_basis.y.normalized(), 1 | 2, self, [get_rid()])
var _throw_t := -1.0                   # >= 0 while the throw animation winds up
var _lift_t := -1.0                    # >= 0 while he bends down and lifts the case
# Clip timing (rend_carry_motion): the pick-up bends from 0.9 s, hands at the floor near 1.4 s,
# upright by 3.0 s; the throw winds up from 0.4 s and lets go near 1.5 s.
const LIFT_FROM := 0.9
const LIFT_SPEED := 2.4
const LIFT_TIME := 0.85                # s locked in place while lifting
const THROW_FROM := 0.4
const THROW_SPEED := 2.6
const THROW_RELEASE := 0.42            # s into the throw when the case leaves his hands
const THROW_TIME := 0.62
const THROW_VELOCITY := Vector3(10.0, 1.6, 0.0)  # flat: crosses a robot at chest height
var _dying := false                     # Tod bis Respawn: keine Locomotion mehr

var crouching := false
var _crouch_attack := false
var _dash_left := 0.0
var _dash_cooldown := 0.0
var _dash_dir := 1.0
var _attack_buffer := 0.0
var _standing_shape: CapsuleShape3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2  # world and robots: on the floor strip they block each other
	$HitPivot/HitArea.collision_mask = 2
	$Collision.shape = $Collision.shape.duplicate()
	_standing_shape = $Collision.shape.duplicate()
	_standing_shape.height = 1.65
	_setup_guard_input()
	_setup_hero()
	_slash_trail = preload("res://modules/vfx/slash_trail.gd").new()
	add_child(_slash_trail)
	shield_visual = preload("res://shield_visual.gd").new()
	add_child(shield_visual)
	shield_visual.hide()
	if _hero_anim:
		_retime_clip("slash_light", 0.30, 0.55, 0.85, 0.16, 0.41, 0.59)
		_retime_clip("slash_combo_2", 0.08, 0.32, 0.75, 0.08, 0.32, 0.50)

func _setup_guard_input() -> void:
	if InputMap.has_action("guard"):return
	InputMap.add_action("guard")
	var key:=InputEventKey.new();key.physical_keycode=KEY_L
	InputMap.action_add_event("guard",key)
	var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("guard",mouse)
	var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_LEFT_SHOULDER
	InputMap.action_add_event("guard",pad)
	for n in 4:
		var action := "weapon_%d" % (n + 1)
		if InputMap.has_action(action):continue
		InputMap.add_action(action)
		var number := InputEventKey.new();number.physical_keycode = KEY_1 + n;InputMap.action_add_event(action, number)
	if not InputMap.has_action("weapon_next"):
		InputMap.add_action("weapon_next");InputMap.add_action("weapon_prev")
		var down := InputEventMouseButton.new();down.button_index = MOUSE_BUTTON_WHEEL_DOWN;InputMap.action_add_event("weapon_next", down)
		var up := InputEventMouseButton.new();up.button_index = MOUSE_BUTTON_WHEEL_UP;InputMap.action_add_event("weapon_prev", up)
		var back := InputEventJoypadButton.new();back.button_index = JOY_BUTTON_BACK;InputMap.action_add_event("weapon_next", back)
	if not InputMap.has_action("reload"):
		# Reload: R, left stick click.
		InputMap.add_action("reload")
		var r_key := InputEventKey.new();r_key.physical_keycode = KEY_R;InputMap.action_add_event("reload", r_key)
		var stick := InputEventJoypadButton.new();stick.button_index = JOY_BUTTON_LEFT_STICK;InputMap.action_add_event("reload", stick)
	if not InputMap.has_action("fire"):
		# Firearms: U, left mouse button, right trigger.
		InputMap.add_action("fire",0.4)
		var fire_key:=InputEventKey.new();fire_key.physical_keycode=KEY_U;InputMap.action_add_event("fire",fire_key)
		var fire_mouse:=InputEventMouseButton.new();fire_mouse.button_index=MOUSE_BUTTON_LEFT;InputMap.action_add_event("fire",fire_mouse)
		var trigger:=InputEventJoypadMotion.new();trigger.axis=JOY_AXIS_TRIGGER_RIGHT;trigger.axis_value=1.0;InputMap.action_add_event("fire",trigger)

func _release_guard() -> void:
	guard.set_guard(false)
	_guard_require_release = Input.is_action_pressed("guard")

func _update_guard(delta: float) -> void:
	guard.tick(delta)
	var held:=Input.is_action_pressed("guard")
	if not held:_guard_require_release=false
	var allowed:=shield_unlocked and not is_instance_valid(gun) and not _guard_require_release and _attack_phase==0 and _dash_left<=0 and _hit_lock<=0 and is_on_floor()
	guard.set_guard(held and allowed)
	if shield_visual:
		shield_visual.visible=shield_unlocked and not _dying

func _retime_clip(clip: String, a: float, b: float, c: float, x: float, y: float, z: float) -> void:
	# Preserve the actual cutting motion; shorten anticipation and idle recovery only.
	if not _hero_anim.has_animation(clip):
		return
	var anim := _hero_anim.get_animation(clip).duplicate() as Animation
	for track in anim.get_track_count():
		for key in anim.track_get_key_count(track):
			var t := anim.track_get_key_time(track, key)
			var mapped := t / a * x if t <= a else x + (t-a)/(b-a)*(y-x) if t <= b else y + (t-b)/(c-b)*(z-y)
			anim.track_set_key_time(track, key, mapped)
	anim.length = z
	var lib := _hero_anim.get_animation_library("")
	lib.remove_animation(clip)
	lib.add_animation(clip, anim)

# Speed across the floor strip, depth included.
func ground_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

func hurt_height() -> float:
	return 1.05 if crouching else 1.65

func _can_stand() -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _standing_shape
	q.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.845, 0))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	q.margin = 0.001
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()

func _cancel_attack() -> void:
	_blade_contact.clear()
	if _slash_trail: _slash_trail.clear()
	_attack_phase = 0
	_seq = 0
	_combo_pending = false
	_attack_buffer = 0.0
	_hit_ids.clear()

func _update_defense(delta: float, axis: float) -> void:
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_dash_left = maxf(0.0, _dash_left - delta)
	var want := is_on_floor() and _dash_left <= 0.0 and ((_attack_phase == 0 and Input.is_action_pressed("crouch")) or (_attack_phase > 0 and _crouch_attack))
	if not want and crouching and not _can_stand():
		want = true
	crouching = want
	$Collision.shape.height = hurt_height()
	$Collision.position.y = hurt_height() * 0.5
	if Input.is_action_just_pressed("dodge") and _dash_cooldown <= 0.0 and not _dying and _hit_lock <= 0.0 and not crouching and (_attack_phase == 0 or _attack_phase == 3):
		_cancel_attack()
		_release_guard()
		_dash_left = 0.18
		_dash_cooldown = 0.62
		_dash_dir = signf(axis) if absf(axis) > 0.1 else facing
		_iframes = maxf(_iframes, 0.14)
		_play("run", 1.0, true)
		FX.dash_flash(global_position, Vector3(_dash_dir, 0, 0))


func _setup_hero() -> void:
	const HERO := "res://assets3d/releases/hero_v05/characters/hero_rendrun.glb"
	const ARM_MODEL := "res://assets/models/weapon/weapon_arm_detached.glb"
	if not ResourceLoader.exists(HERO):
		return                                  # Fallback: Platzhalter-Kapsel bleibt
	_hero = load(HERO).instantiate()
	pivot.add_child(_hero)
	visual.visible = false
	blade.visible = false
	arm.visible = false
	_hero_skel = _hero.find_child("Skeleton3D", true, false) as Skeleton3D
	_hero_anim = _hero.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _hero_anim:
		for clip in ["idle", "walk", "run"]:
			if _hero_anim.has_animation(clip):
				_hero_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		# Meshy hit/pain reactions retargeted onto Rend's rig (tools/retarget_clips.gd), in place.
		_hero_anim.add_animation_library("react",preload("res://generated/rend_hit_motion.tres"))
		# Meshy pick-up / carry / throw and gun handling (asset_library/meshy/2026-10-23_actions).
		_hero_anim.add_animation_library("carry",preload("res://generated/rend_carry_motion.tres"))
		_hero_anim.add_animation_library("gun",preload("res://generated/rend_gun_motion.tres"))
	if _hero_skel:
		var modifier := preload("res://crouch_pose.gd").new()
		_crouch_modifier = modifier
		modifier.actor = self
		modifier.combat_stance = true
		_hero_skel.add_child(modifier)
		var defense_pose:=preload("res://guard_pose.gd").new()
		defense_pose.actor=self
		_hero_skel.add_child(defense_pose)
		# Hands on the drawn gun (two-bone IK), before the hit reactions shake it.
		_gun_hold=preload("res://modules/combat/gun_hold_pose.gd").new()
		_gun_hold.actor=self
		_hero_skel.add_child(_gun_hold)
		_gun_hold.modification_processed.connect(_fire_pending_shot)
		# Last in the stack: the blow acts on whatever pose Rend is in.
		_hit_overlay=preload("res://modules/combat/hit_overlay.gd").new()
		_hit_overlay.arm_weight=0.7
		_hero_skel.add_child(_hit_overlay)
		_hit_physics=preload("res://modules/combat/hit_physics.gd").new()
		_hit_physics.actor=self;_hit_physics.mixamo_prefix="mixamorig_"
		_hero_skel.add_child(_hit_physics)
		_hero_skel.skeleton_updated.connect(_cache_crouched_blade_pose)
	# Mechanical arm grip attaches to the existing hand bone.
	var hand_bone := "hand_r"
	if _hero_skel and _hero_skel.find_bone(hand_bone) < 0:
		hand_bone = "mixamorig_RightHand"
	if _hero_skel and _hero_skel.find_bone(hand_bone) >= 0 and ResourceLoader.exists(ARM_MODEL):
		var att := BoneAttachment3D.new()
		att.bone_name = hand_bone
		_blade_hand = _hero_skel.find_bone(hand_bone)
		_hero_skel.add_child(att)
		_sword_model=load(ARM_MODEL).instantiate()
		att.add_child(_sword_model)
		_starter_model=_sword_model
		_heavy_model=load(ARM_MODEL).instantiate()
		_heavy_model.scale = Vector3(1.15, 1.08, 1.15)
		_heavy_model.name="ReinforcedArm"
		att.add_child(_heavy_model)
		_heavy_model.add_child(preload("res://modules/visuals/arm_reinforcement.gd").new())
		_servo_model=preload("res://assets3d/weapons/arm_servo_v1/model.glb").instantiate()
		_servo_model.name="ServoAttachment";_servo_model.position=Vector3(0,.13,0);_servo_model.scale=Vector3.ONE*1.3;_servo_model.visible=false
		_heavy_model.add_child(_servo_model)
		equip_weapon(weapon_id)

func _play(anim_name: String, speed := 1.0, force := false) -> void:
	if _hero_anim == null or not _hero_anim.has_animation(anim_name):
		return
	if not force and _anim_state == anim_name and _hero_anim.is_playing():
		return
	# Ease locomotion poses without hiding the accepted sword anticipation.
	var blend := 0.04
	if anim_name in ["idle", "walk", "run"]:
		blend = 0.12 if _anim_state in ["idle", "walk", "run"] else 0.08
	_anim_state = anim_name
	_hero_anim.speed_scale = 1.0
	_hero_anim.play(anim_name, blend, speed)

func reset_state() -> void:
	if _slash_trail: _slash_trail.clear()
	if not has_slot(slot):select_slot(SLOT_MELEE if has_slot(SLOT_MELEE) else SLOT_FREE, true)
	if is_instance_valid(_death_physics):
		if is_instance_valid(_death_physics.physics_root):_death_physics.physics_root.queue_free()
		_death_physics.queue_free();_death_physics=null
		collision_layer=4
	# Respawn: Kampfzustand komplett zuruecksetzen, sonst haengt z. B. ein offener Combo-Puffer
	_dying = false
	_foot_contacts.reset();_step_distance=0.0
	guard.reset()
	_guard_require_release=Input.is_action_pressed("guard")
	_dash_left = 0.0
	_dash_cooldown = 0.0
	_attack_buffer = 0.0
	crouching = false
	_hit_lock = 0.0
	_land_lock = 0.0
	_attack_phase = 0
	_attack_timer = 0.0
	_attack_elapsed = 0.0
	_seq = 0
	_combo_pending = false
	_attack_key_was = Input.is_action_pressed("attack")
	_hit_ids.clear()
	_iframes = 0.6
	velocity = Vector3.ZERO

func play_death_anim() -> void:
	if _slash_trail: _slash_trail.clear()
	drop_carried()
	if is_instance_valid(gun):gun.queue_free();gun = null
	holstered.clear()
	_dying = true
	_release_guard()
	if shield_visual:shield_visual.hide()
	# Tod bricht den Angriff komplett ab: sonst läuft die Trefferphase unter
	# dem Death-Clip weiter und ein alter Puffer kann im nächsten Leben zünden.
	_attack_phase = 0
	_seq = 0
	_combo_pending = false
	FX.voice("rend_death", -2.0)
	# He collapses like the robots do: a jointed ragdoll takes over from the current pose,
	# thrown away from the blow. The death clips remain the fallback.
	if is_instance_valid(_hit_physics) and _hit_physics.is_reacting():_hit_physics.physics_root.queue_free()
	if _hero_skel and not is_instance_valid(_death_physics) and is_on_floor():
		var ragdoll := preload("res://modules/combat/articulated_death.gd").new()
		_hero_skel.add_child(ragdoll)
		if ragdoll.build(self, Vector3(_last_hit_dir * 5.0, 1.2, 0.0), "mixamorig_"):
			_death_physics = ragdoll
			if _hero_anim:_hero_anim.pause()
			collision_layer = 0  # robots walk over the body; the capsule still stands on the floor
			velocity = Vector3.ZERO
			return
		ragdoll.queue_free()
	# Fall away from the blow: pushed backwards when struck from the front.
	var clip := "react/death_back" if _last_hit_dir == -facing else "react/death_front"
	if _hero_anim and not _hero_anim.has_animation(clip):clip="death"
	if _hero_anim and _hero_anim.has_animation(clip):
		_anim_state = clip
		_hero_anim.speed_scale = 1.0
		_hero_anim.play(clip, 0.08)

## Straps on a shield of `kind` ("salvage" or "riot"). Returns the kind he gave up ("" if
## none) so it can be dropped. The riot shield spreads blows: blocking costs less stamina.
func take_shield(kind: String) -> String:
	var previous := shield_kind if shield_unlocked else ""
	shield_kind = kind;shield_unlocked = true
	guard.block_cost = 15.0 if kind == "riot" else guard.BLOCK_COST
	if shield_visual:shield_visual.set_kind(kind)
	return previous

## HUD line: the four slots, the drawn one in brackets.
func slot_summary() -> String:
	var names := []
	for n in [SLOT_FREE, SLOT_MELEE, SLOT_SIDEARM, SLOT_LONG]:
		var label := ""
		match n:
			SLOT_FREE:label = UI_TEXT.t("player_slot_hands")
			SLOT_MELEE:label = (UI_TEXT.t("player_slot_arm") if weapon_id == "robot_arm" else UI_TEXT.t("player_slot_crusher_arm")) if has_slot(n) else "—"
			_:
				if holstered.has(n):
					var drawn: bool = n == slot and is_instance_valid(gun)
					var ammo: int = gun.ammo if drawn else holstered[n].ammo
					var spare: int = gun.reserve if drawn else holstered[n].reserve
					label = "%s %d/%d" % [preload("res://modules/combat/gun.gd").label_of(holstered[n].kind), ammo, spare]
				else:label = "—"
		names.append(("[%d %s]" if n == slot else "%d %s") % [n, label])
	return "  ".join(names)

## Takes a firearm (from a fallen robot) carrying `rounds` in all: a full magazine, the rest
## as reserve. The same kind again only adds its rounds to the reserve. Stores it in its slot
## and draws it. Returns the gun it replaced ({kind, ammo = all its rounds}, or empty) so the
## caller can drop it where it lay.
func equip_gun(kind: String, rounds: int) -> Dictionary:
	var target := SLOT_SIDEARM if kind in SIDEARMS else SLOT_LONG
	_stow_gun()
	var replaced: Dictionary = holstered.get(target, {})
	if replaced.get("kind", "") == kind:
		holstered[target].reserve += rounds
		replaced = {}
	else:
		if not replaced.is_empty():replaced = {"kind": replaced.kind, "ammo": replaced.ammo + replaced.reserve}
		var mag := mag_size(kind)
		holstered[target] = {"kind": kind, "ammo": mini(rounds, mag), "reserve": maxi(0, rounds - mag)}
	select_slot(target, true)
	return replaced

## Magazine size of a gun kind with his mods fitted.
func mag_size(kind: String) -> int:
	var base: int = preload("res://modules/combat/gun.gd").SPECS[kind].ammo
	return int(ceil(base * (1.5 if "extmag" in gun_mods.get(kind, []) else 1.0)))

## Fits a mod to a gun kind (bench); re-draws the drawn gun so the part shows.
func fit_mod(kind: String, mod: String) -> void:
	var list: Array = gun_mods.get(kind, [])
	if mod in list:return
	list.append(mod);gun_mods[kind] = list
	if is_instance_valid(gun) and gun.kind == kind:select_slot(slot, true)

func has_slot(n: int) -> bool:
	match n:
		SLOT_FREE:return true
		SLOT_MELEE:return not weapon_id.is_empty()
		_:return holstered.has(n)

## Draws the weapon of slot n (no-op if he does not carry one there).
func select_slot(n: int, force := false) -> void:
	if not has_slot(n) or (n == slot and not force) or _dying:return
	_stow_gun()
	_cancel_attack()
	slot = n
	if _starter_model and _heavy_model:
		_starter_model.visible = slot == SLOT_MELEE and weapon_id == "robot_arm"
		_heavy_model.visible = slot == SLOT_MELEE and weapon_id == "reinforced_arm"
	if holstered.has(slot):
		gun = preload("res://modules/combat/gun.gd").make(holstered[slot].kind)
		gun.mods = gun_mods.get(holstered[slot].kind, []).duplicate()
		gun.ammo = holstered[slot].ammo;gun.reserve = holstered[slot].reserve;gun.top_level = true
		add_child(gun)
		gun.emptied.connect(_gun_emptied)
	FX.play("block", 1.6, -16.0)  # a short metallic clack as the weapon comes up
	slot_changed.emit(slot)

func cycle_slot(step: int) -> void:
	var n := slot
	for i in 4:
		n = wrapi(n - 1 + step, 0, 4) + 1
		if has_slot(n):select_slot(n);return

func _stow_gun() -> void:
	if not is_instance_valid(gun):return
	if holstered.has(slot):
		# A reload cut short by holstering does not lose the rounds: they stay in reserve.
		holstered[slot].ammo = gun.ammo;holstered[slot].reserve = gun.reserve
	gun.queue_free();gun = null

func _gun_emptied() -> void:
	# Out of rounds: he tosses it away a beat after the last shot and draws the arm.
	var spent := gun;gun = null
	holstered.erase(slot)
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(spent):spent.queue_free()
	if slot != SLOT_MELEE:select_slot(SLOT_MELEE if has_slot(SLOT_MELEE) else SLOT_FREE)

func _read_slot_input() -> void:
	for n in 4:
		if Input.is_action_just_pressed("weapon_%d" % (n + 1)):select_slot(n + 1)
	if Input.is_action_just_pressed("weapon_next"):cycle_slot(1)
	if Input.is_action_just_pressed("weapon_prev"):cycle_slot(-1)
	if Input.is_action_just_pressed("reload") and is_instance_valid(gun) and not carried and not _dying:gun.reload()

func _update_gun(delta: float) -> void:
	_aim_t = maxf(0.0, _aim_t - delta)
	var holding := is_instance_valid(gun) and not carried and not _dying
	if is_instance_valid(_gun_hold):
		# The hold modifier shoulders the gun and places it; blend in on draw, out on holster.
		_gun_hold.gun = gun if is_instance_valid(gun) else null
		_gun_hold.weight = move_toward(_gun_hold.weight, 1.0 if holding else 0.0, delta * 7.0)
		var wants_aim := _aim_t > 0.0 or Input.is_action_pressed("fire") or (Input.is_action_pressed("attack") and slot >= SLOT_SIDEARM)
		_gun_hold.aim = move_toward(_gun_hold.aim, 1.0 if wants_aim else 0.0, delta * 14.0)
		_gun_hold.aim_point = _aim_target()
	if not is_instance_valid(gun):return
	var forward := Vector3(facing, 0, 0)
	if not is_instance_valid(_gun_hold):
		gun.global_transform = Transform3D(Basis(Vector3.UP, forward, Vector3.UP.cross(forward)), global_position + Vector3(facing * 0.45, 1.25, 0))
	if _dying or carried or _hit_lock > 0.0 or _attack_phase > 0 or _dash_left > 0.0:return
	# Fires only once the gun is up, along its barrel, from its muzzle.
	var raised: bool = not is_instance_valid(_gun_hold) or _gun_hold.aim > 0.8
	if (Input.is_action_pressed("fire") or Input.is_action_pressed("attack")) and gun.can_fire() and raised:
		var kick := 0.2 if gun.kind == "scattergun" else 0.06
		if is_instance_valid(_gun_hold):
			_shot_pending = true  # fired right after the hold has placed the gun this frame
		else:
			gun.fire(_aim_direction(gun.muzzle()), 1 | 2, self, [get_rid()])
		FX.add_shake(kick, Vector3(-facing, 0.2, 0))
		_aim_t = 0.4
		_update_locomotion(true)

# Aim assist for the 2.5D strip: at the chest of the nearest robot ahead in his depth lane
# (within 12 m), otherwise level at chest height a few metres out.
func _aim_direction(from: Vector3) -> Vector3:
	return (_aim_target() - from).normalized()

## What he points at: the chest of the nearest robot ahead in his depth lane (12 m), else
## chest height a few metres along his body's facing.
func _aim_target() -> Vector3:
	var body_forward := (pivot.global_basis.x * Vector3(1, 0, 1)).normalized()
	var target := global_position + body_forward * 6.0 + Vector3(0, 1.25, 0)
	var best := 12.0
	for foe in get_tree().get_nodes_in_group("enemies"):
		if foe.get("_dead") == true or not foe is Node3D:continue
		var dx: float = (foe.global_position.x - global_position.x) * facing
		if dx <= 0.3 or dx > best or absf(foe.global_position.z - global_position.z) > 0.7:continue
		best = dx;target = foe.global_position + Vector3(0, 1.0, 0)
	return target

## Cases on the floor: Rend shoves what he walks into.
func _push_loose_bodies(speed: float) -> void:
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider() as RigidBody3D
		if body and not body.freeze and absf(hit.get_normal().y) < 0.5:
			# Walking pace into the case's mass: a slow shove, not a kick.
			body.apply_central_impulse(-hit.get_normal() * minf(4.5, speed * 0.9))

## Nearest loose case Rend could lift: in front of him, at his depth.
func throwable_in_reach() -> RigidBody3D:
	if carried or _dying or not is_on_floor():return null
	var best: RigidBody3D = null;var best_d := 1.25
	for crate in get_tree().get_nodes_in_group("throwables"):
		var c := crate as RigidBody3D
		if c.carried or c.is_thrown():continue
		var dx := c.global_position.x - global_position.x
		if absf(c.global_position.z - global_position.z) > 0.6 or absf(dx) > best_d or c.global_position.y > global_position.y + 0.8:continue
		if dx * facing < -0.2:continue
		best = c;best_d = absf(dx)
	return best

func pick_up(crate: RigidBody3D) -> void:
	if crate == null or carried:return
	_cancel_attack();_release_guard()
	carried = crate;crate.pick_up()
	_lift_t = 0.0
	if _hero_anim and _hero_anim.has_animation("carry/pickup"):
		_anim_state = "carry/pickup";_hero_anim.play("carry/pickup", 0.1);_hero_anim.seek(LIFT_FROM, true);_hero_anim.speed_scale = LIFT_SPEED

## Sets the case down in front of him (no throw).
func drop_carried() -> void:
	if not carried:return
	var crate := carried;carried = null;_throw_t = -1.0;_lift_t = -1.0
	crate.global_position = global_position + Vector3(facing * 0.75, 0.35, 0)
	crate.release(Vector3.ZERO)

func _begin_throw() -> void:
	_throw_t = 0.0;_lift_t = -1.0
	if _hero_anim and _hero_anim.has_animation("carry/throw"):
		_anim_state = "carry/throw";_hero_anim.play("carry/throw", 0.08);_hero_anim.seek(THROW_FROM, true);_hero_anim.speed_scale = THROW_SPEED

# Where the case sits: between his hands (so it follows every carry clip), a little ahead.
func _hands_hold_point() -> Vector3:
	if _hero_skel:
		var l := _hero_skel.find_bone("mixamorig_LeftHand");var r := _hero_skel.find_bone("mixamorig_RightHand")
		if l >= 0 and r >= 0:
			var mid := (_hero_skel.global_transform * _hero_skel.get_bone_global_pose(l).origin + _hero_skel.global_transform * _hero_skel.get_bone_global_pose(r).origin) * 0.5
			return mid + Vector3(facing * 0.22, -0.05, 0)
	return global_position + Vector3(facing * 0.5, 1.05, 0)

func _update_carry(delta: float) -> void:
	if _throw_t >= 0.0 and carried == null:
		# After the release: let the follow-through play, then back to normal movement.
		_throw_t += delta
		if _throw_t >= THROW_TIME:_throw_t = -1.0;_update_locomotion(true)
		return
	if not carried:return
	if not is_instance_valid(carried):carried = null;return
	if _lift_t >= 0.0:
		_lift_t += delta
		if _lift_t >= LIFT_TIME:_lift_t = -1.0;_update_locomotion(true)
	if _throw_t >= 0.0:
		_throw_t += delta
		if _throw_t >= THROW_RELEASE:
			var crate := carried;carried = null
			crate.global_position = Vector3(global_position.x + facing * 0.6, maxf(crate.global_position.y, global_position.y + 1.1), global_position.z)
			crate.release(Vector3(THROW_VELOCITY.x * facing, THROW_VELOCITY.y, 0) + Vector3(velocity.x * 0.5, 0, 0))
			FX.play("swing", 0.7, -4.0)
			return
	carried.global_position = carried.global_position.lerp(_hands_hold_point(), minf(1.0, 22.0 * delta))
	carried.global_rotation = Vector3(0, pivot.rotation.y, 0)

func _update_locomotion(force := false) -> void:
	if _hero == null or _attack_phase > 0 or _dying:
		return
	if _lift_t >= 0.0 or _throw_t >= 0.0:return  # the lift or throw clip owns the body
	if carried and _hero_anim and _hero_anim.has_animation("carry/walk"):
		var moving := ground_speed() > 0.3
		if _anim_state != "carry/walk" or force:_play("carry/walk", 1.0, true)
		_hero_anim.speed_scale = clampf(ground_speed() / 2.2, 0.0, 1.4) if moving else 0.0
		return
	if _land_lock > 0.0 or _hit_lock > 0.0:
		return
	# Let a pain reaction finish while Rend stands; any movement takes over at once.
	var want := "idle"
	if not is_on_floor():
		want = "jump" if velocity.y > 0.5 else "fall"
	elif ground_speed() > (4.0 if _anim_state == "run" else 4.8):
		want = "run"
	elif ground_speed() > (0.2 if _anim_state in ["walk", "run"] else 0.4):
		want = "walk"
	if want != _anim_state or force:
		_play(want, 0.6 if want == "fall" else 1.0, want == "jump" or force)
	# Match only the crouch walk cadence to travel; every new action resets this.
	_hero_anim.speed_scale = clampf(ground_speed() * _hero_anim.current_animation_length / 1.05, 0.5, 3.0) if crouching and want == "walk" else 1.0

func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector3.ZERO
		return
	_update_guard(delta)
	_iframes = maxf(0.0, _iframes - delta)
	_attack_buffer = maxf(0.0, _attack_buffer - delta)
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_attack_elapsed += delta if _attack_phase > 0 else 0.0
	if _attack_timer <= 0.0 and _attack_phase > 0:
		if _attack_phase == 1:
			_attack_phase = 2
			_attack_timer = _active_dur
		elif _attack_phase == 2:
			_attack_phase = 3
			_attack_timer = (_attack_dur - _startup_dur - _active_dur) * _attack_recovery_factor
			# Only the return-to-ready phase is faster; windup and hit sweep stay intact.
			if _hero_anim:_hero_anim.speed_scale=ATTACK_TEMPO/_attack_recovery_factor
		else:
			_attack_phase = 0
			_seq = 0
			_combo_pending = false           # kein veralteter Puffer zuendet den naechsten Hieb
			_update_locomotion(true)         # Recovery-Ende -> zurueck in Locomotion

	# Richtung: Blick folgt IMMER der letzten Eingabe (auch während Attacke)
	var input_dir := Input.get_axis("move_left", "move_right")
	var depth_dir := Input.get_axis("move_up", "move_down")
	if absf(input_dir) > 0.1 and _attack_phase != 2 and not guard.is_guarding():
		facing = signf(input_dir)
	_update_defense(delta, input_dir)
	_pivot_hitbox()

	var attacking := _attack_phase > 0
	var gait := 0.24 if crouching else 0.4 if guard.is_guarding() else 0.72 if attacking else 0.0 if _lift_t >= 0.0 or _throw_t >= 0.0 else 0.62 if carried else 1.0
	var target := input_dir * move_speed * gait
	var target_z := depth_dir * move_speed * depth_speed_factor * gait
	if _dash_left > 0.0:
		target = _dash_dir * 14.0
		target_z = 0.0

	# Reibung / Beschleunigung
	var weight := friction if is_on_floor() and input_dir == 0.0 else acceleration
	var weight_z := friction if is_on_floor() and depth_dir == 0.0 else acceleration
	if _hit_lock <= 0.0:
		velocity.x = target if _dash_left > 0.0 else move_toward(velocity.x, target, weight * delta)
		velocity.z = move_toward(velocity.z, target_z, weight_z * delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)  # the shove bleeds off under the feet
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)

	# Gravity (variable, für besseres Feel)
	var gravity := get_gravity().y
	if not is_on_floor():
		if velocity.y < 0.0:
			gravity *= fast_fall_mult
		elif not Input.is_action_pressed("jump"):
			gravity *= 2.2               # Jump-Cut: Taste loslassen = kürzerer Sprung
	velocity.y += gravity * delta * gravity_mult

	# Coyote-Time: kurz nach Kantenrand noch springbar
	if is_on_floor():
		_coyote = coyote_time
	else:
		_coyote -= delta

	# Jump-Buffer: Taste etwas vor Landung drücken reicht
	_jump_buffer -= delta
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time

	if _jump_buffer > 0.0 and _coyote > 0.0 and not crouching:
		_release_guard()
		_land_lock = 0.0 # A buffered jump must not retain the landing pose.
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote = 0.0

	# Lande-Squash
	if is_on_floor() and not _was_on_floor:
		_squash(true)
		if _hero and velocity.y <= 0.0 and _land_lock <= 0.0 and _attack_phase <= 0 and not _dying:  # Tod-Clip nicht ueberschreiben
			_land_lock = 0.18
			_play("land", 1.4, true)     # 0,63s Clip komprimiert; Ende halten bis Bodenkontakt
	_was_on_floor = is_on_floor()
	_land_lock = maxf(0.0, _land_lock - delta)
	var was_locked := _hit_lock > 0.0
	_hit_lock = maxf(0.0, _hit_lock - delta)
	if was_locked and _hit_lock <= 0.0 and not _dying:
		_update_locomotion(true)  # resume from the held pose once he has caught himself

	# Attacke [P04]: Flankenerkennung — Halten/Key-Echo zaehlt nicht als zweiter Druck.
	var attack_now := Input.is_action_pressed("attack")
	var attack_edge := attack_now and not _attack_key_was
	_attack_key_was = attack_now
	if attack_edge and carried and _throw_t < 0.0 and _lift_t < 0.0 and _hit_lock <= 0.0:
		_begin_throw()
	elif attack_edge and not _dying and _hit_lock <= 0.0 and _dash_left <= 0.0 and not carried:
		if _attack_phase == 0:
			_start_attack(1)
		elif _seq == 3 and _attack_phase == 3:
			_attack_buffer = 0.16
		elif _seq == 1 and _attack_elapsed <= COMBO_BUFFER_S / (0.8 if weapon_id=="reinforced_arm" else 1.0):
			_combo_pending = true           # Puffer: zweiter Druck bis 0,45s
	# Combo-Puffer zuBuendung: erst NACH dem light-Trefferfenster, damit der
	# erste Hieb fertig durchspielen kann und nicht seinen eigenen Treffer verliert.
	if _combo_pending and _attack_phase > 0 and _attack_elapsed >= _combo_fire_at:
		_combo_pending = false
		_start_attack(3)

	if _attack_phase == 0 and _attack_buffer > 0.0 and _hit_lock <= 0.0:
		_attack_buffer = 0.0
		_start_attack(1)
	# Blickrichtung des Körpers
	if _hero:
		# Facing stays left/right; walking into the depth turns the body toward it.
		var depth_turn := clampf(-velocity.z / move_speed, -1.0, 1.0) * 0.85 * facing
		pivot.rotation.y = lerp_angle(pivot.rotation.y, (0.0 if facing > 0.0 else PI) + depth_turn, minf(1.0, 14.0 * delta))
	if absf(velocity.x) > 0.2:
		visual.rotation.y = lerp_angle(visual.rotation.y, PI / 2.0 * facing, 12.0 * delta)
	_update_locomotion()

	# A dodge slips past robots; otherwise their bodies block Rend, and he cannot walk
	# closer than the push-box gap (no hugging: fights stay readable at weapon distance).
	set_collision_mask_value(2, _dash_left <= 0.0)
	if _dash_left <= 0.0:
		for foe in get_tree().get_nodes_in_group("enemies"):
			if not foe.has_method("_keep_push_gap") or foe._dead or foe.collision_layer & 2 == 0 or absf(foe.global_position.z - global_position.z) >= foe.PUSH_DEPTH:continue
			var gap: float = foe.global_position.x - global_position.x
			if absf(gap) < foe.PUSH_GAP and velocity.x * signf(gap) > 0.0:velocity.x = 0.0
	var grounded_before_slide := is_on_floor()
	var impact_speed := maxf(0.0, -velocity.y)
	var movement_start := global_position
	_update_carry(delta)
	_read_slot_input()
	_update_gun(delta)
	# Pushing follows what he is trying to do: blocked by the case, his velocity is near zero.
	var push_speed := Vector2(Input.get_axis("move_left","move_right"), Input.get_axis("move_up","move_down")).length() * move_speed * (0.62 if carried else 1.0)
	move_and_slide()
	_push_loose_bodies(push_speed)
	if global_position.z < depth_min or global_position.z > depth_max:
		global_position.z = clampf(global_position.z, depth_min, depth_max)
		velocity.z = 0.0
	_movement_audio(grounded_before_slide,Vector2(global_position.x-movement_start.x,global_position.z-movement_start.z).length())
	if not grounded_before_slide and is_on_floor() and impact_speed >= 4.0:
		FX.landing_dust(global_position + Vector3(0, 0.035, 0.12), impact_speed)
		FX.play("land_metal",1.0,lerpf(-10.0,-5.0,clampf((impact_speed-4.0)/8.0,0.0,1.0)))

	# Trefferprüfung NUR im aktiven Fenster — ein Treffer pro Ziel (siehe _check_hits)
	if _attack_phase == 2:
		_check_hits(delta)
	else:
		_blade_contact.clear()
		if _slash_trail: _slash_trail.clear()

func _pivot_hitbox() -> void:
	hit_pivot.scale.x = facing                    # Trefferzone spiegelt mit Blickrichtung
	hit_pivot.rotation.y = 0.0
	arm.scale.x = facing

func equip_weapon(id: String) -> void:
	weapon_id=id if id in ["robot_arm", "reinforced_arm"] else ""
	_cancel_attack()
	if _starter_model and _heavy_model:
		_sword_model=_heavy_model if weapon_id=="reinforced_arm" else _starter_model
	# Taking or upgrading the arm draws it.
	if not weapon_id.is_empty():select_slot(SLOT_MELEE, true)
	else:
		slot = SLOT_FREE  # nothing to draw yet
		if _starter_model and _heavy_model:_starter_model.visible=false;_heavy_model.visible=false

func set_arm_servo(enabled: bool) -> void:
	_servo_installed=enabled
	if is_instance_valid(_servo_model):_servo_model.visible=enabled

func _start_attack(seq_id: int) -> void:
	if weapon_id.is_empty() or slot != SLOT_MELEE: return
	_attack_recovery_factor=ARM_PREFIX.RECOVERY_MULTIPLIER if weapon_id=="reinforced_arm" and _servo_installed else 1.0
	if _attack_phase == 0:_crouch_attack=crouching
	_crouched_blade_valid=false
	_release_guard()
	# V10: runtime-retimed hero_v05 copies play at 1.0x.
	# Damage is gated by the active phase AND the evaluated blade sweep.
	_blade_contact.clear()
	if _slash_trail: _slash_trail.clear()
	_seq = seq_id
	_attack_phase = 1
	_attack_timer = _startup_dur if _startup_dur > 0.0 else 0.001
	_attack_elapsed = 0.0
	_hit_ids.clear()
	if seq_id == 1:
		_startup_dur = 0.16                 # Fenster vor dem Kontakt-Peak
		_active_dur = 0.25                  # Kontakt-Peak liegt mittig bei 0.425s
		_attack_dur = 0.59                  # retimed anticipation/recovery
		_combo_fire_at = 0.42               # after first active window
		FX.play("swing", 1.0, -6.0)
		FX.add_shake(0.07)
		_play("slash_light", 0.8 if weapon_id=="reinforced_arm" else 1.0, true)
	else:  # 3 = slash_combo_2
		_startup_dur = 0.08
		_active_dur = 0.24
		_attack_dur = 0.50                  # retimed recovery
		_combo_fire_at = 999.0              # kein Anschluss aus der Combo
		FX.play("swing", 0.85, -5.0)
		FX.add_shake(0.12)
		_play("slash_combo_2", 0.8 if weapon_id=="reinforced_arm" else 1.0, true)

	if weapon_id=="reinforced_arm":
		_startup_dur/=0.8;_active_dur/=0.8;_attack_dur/=0.8;_combo_fire_at/=0.8
	# Snappier swings (Dead Cells pace): the whole strike plays ATTACK_TEMPO times faster.
	_startup_dur/=ATTACK_TEMPO;_active_dur/=ATTACK_TEMPO;_attack_dur/=ATTACK_TEMPO;_combo_fire_at/=ATTACK_TEMPO
	if _hero_anim:_hero_anim.speed_scale*=ATTACK_TEMPO
	_attack_timer = _startup_dur
	velocity.x += facing * (0.8 if _crouch_attack else 2.4)

func _check_hits(delta: float = 1.0 / 60.0) -> void:
	if _attack_phase != 2:
		return
	var targets: Array = []
	if _hero_skel and _blade_hand >= 0 and _sword_model:
		# Evaluate the bone directly: BoneAttachment may still contain last frame's pose.
		var hand_world: Transform3D = _crouched_blade_pose if _crouch_attack and _crouched_blade_valid else _hero_skel.global_transform * _hero_skel.get_bone_global_pose(_blade_hand)
		var base := Vector3(0, 0.06, 0)
		var tip := Vector3(0, 0.448, 0)
		if weapon_id == "reinforced_arm":
			base = Vector3(0, 0.06, 0)
			tip = Vector3(0, 0.484, 0)
		# Mechanical arm uses its real contact volume; no luminous sword trail.
		targets = _blade_contact.query(get_world_3d().direct_space_state,
			hand_world * base, hand_world * tip, global_position.z, get_rid())
	else:
		# Asset-less prototype fallback only.
		targets = $HitPivot/HitArea.get_overlapping_bodies()
	for body in targets:
		if not body.has_method("take_melee_hit"):
			continue
		var id: int = body.get_instance_id()
		if _hit_ids.has(id):
			continue
		_hit_ids[id] = true
		var combo := _seq == 3
		# V85: flacher Rekoil — leichte Treffer stauchden nur, Kombo wirft weiter
		var kb := Vector3(facing * (7.5 if combo else 5.5), 1.1 if not combo else 3.2, 0)
		if body.is_in_group("metal_props") and not body.is_broken():
			FX.metal_contact(body.global_position+Vector3(-facing*0.25,0.4,0.25),Vector3(-facing,0.8,0))
		body.take_melee_hit(2 if weapon_id=="reinforced_arm" else 1, kb * (1.2 if weapon_id=="reinforced_arm" else 1.0))
		# Robot impact particles are owned by the target, not a cutting flash.
		# Dead Cells-weight hitstop: the frame freezes long enough for the blow to register.
		FX.hitstop(0.09 if combo else 0.065)
		FX.add_shake(0.35 if combo else 0.24)
		# Enemies play their impact in take_melee_hit, including indirect hits.
		# Props without their own audio retain the attacker's contact sound.
		if not body.get_meta("owns_melee_hit_audio",false):
			FX.play("hit", 0.85 if combo else 1.0, -1.0)

func take_damage(amount: int, from_pos: Vector3, attacker: Node = null) -> void:
	if amount<=0 or _iframes > 0.0 or _dying:
		return
	var result: Dictionary=guard.resolve_hit(amount,(from_pos.x-global_position.x)*facing>0.05)
	if result.outcome in ["parry","block"]:
		guard_contact.emit(result.outcome)
		FX.metal_contact(global_position+Vector3(facing*0.45,1.0,0.15),Vector3(facing,0.7,0),result.outcome=="parry")
		FX.cut_flash(global_position+Vector3(facing*0.45,1.0,0),facing,false)
		FX.play(result.outcome,1.0,-2.0)
		FX.hitstop(0.045 if result.outcome=="parry" else 0.025)
		FX.add_shake(0.25)
		if result.outcome=="parry" and is_instance_valid(attacker) and attacker.has_method("receive_parry"):
			attacker.receive_parry()
		return
	if result.outcome=="break":
		guard_contact.emit("break")
		FX.play("guard_break",1.0,-2.0)
	_release_guard()
	_cancel_attack()
	drop_carried()  # a blow knocks the case out of his hands
	_dash_left = 0.0
	_iframes = 0.8
	hp -= amount
	var hit_dir := signf(global_position.x - from_pos.x)
	_last_hit_dir = hit_dir
	var heavy: bool = amount >= 2 or result.outcome == "break"
	var kind: String = attacker.call("attack_kind") if is_instance_valid(attacker) and attacker.has_method("attack_kind") else ""
	# Impact is carried by a body reaction, not by sliding Rend away: a short shove,
	# a two-stage hitstop and directional camera trauma.
	FX.hitstop(0.06 if heavy else 0.045, 0.04, 0.09 if heavy else 0.06)
	FX.add_shake(0.8 if heavy else 0.55, Vector3(hit_dir, 0.35, 0.0))
	if hp > 0:FX.voice("rend_hurt_heavy" if heavy else "rend_hurt_light")
	FX.damage_flash(1.4 if heavy else 1.0)
	var wound := global_position + Vector3(0, 1.45 if kind == "high" else 1.0, 0)
	FX.blood(wound, 12, 3.0, Vector3(hit_dir, 0.4, 0))
	FX.impact_light(wound + Vector3(-hit_dir * 0.2, 0, 0.3), Color(1.0, .45, .3), 0.9, .08, 2.0)
	if is_on_floor():
		# Feet stay planted: the upper body absorbs the blow (hit_overlay), he is not shoved.
		velocity = Vector3.ZERO
	else:
		velocity = Vector3(hit_dir * (3.0 if heavy else 2.0), 0.8, 0)
	if _hero and hp > 0:
		_hit_lock = maxf(0.45 if heavy else 0.28, guard.break_remaining())
		# The blow stops whatever he was doing: hold that exact pose and let the reaction act on it.
		if is_on_floor() and _hero_anim:_hero_anim.pause()
		# The attacker knows how its weapon travelled; fall back to "away from it".
		var blow: Vector3 = attacker.call("blow_vector") if is_instance_valid(attacker) and attacker.has_method("blow_vector") else Vector3(global_position.x - from_pos.x, 0, global_position.z - from_pos.z)
		var zone: String = attacker.call("blow_zone") if is_instance_valid(attacker) and attacker.has_method("blow_zone") else "head" if kind == "high" else "legs" if kind == "low" else "torso"
		if is_instance_valid(_hit_overlay) and _hero_anim:
			_hit_overlay.play(_hero_anim.get_animation("react/" + _reaction_clip(blow, zone, heavy)), 1.3 if heavy else 1.0)
		# The blow physically throws the struck part; drives catch him again (hit_physics).
		if is_instance_valid(_hit_physics):
			_hit_physics.strike(zone, blow.normalized() * (1.7 if heavy else 1.1))
	if hp <= 0 and not _dying:
		died.emit()   # Double-Emit-Guard: Tod nur einmal

# Which mocap reaction fits the blow: across the body snaps the head aside, from below
# throws the upper body back, a body blow folds him over, anything else is a flinch.
func _reaction_clip(blow: Vector3, zone: String, heavy: bool) -> String:
	var b := blow.normalized()
	if absf(b.z) > 0.6:return "hit_head"
	if b.y > 0.5:return "hit_front"
	if zone == "torso" and absf(b.y) < 0.4:return "hit_body"
	return "hit_front" if heavy and b.y > -0.5 else "hit_light"

func _squash(impact: bool) -> void:
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	pivot.scale = Vector3(1.35, 0.7, 1.35) if impact else Vector3(0.8, 1.25, 0.8)
	_squash_tween = create_tween()
	_squash_tween.tween_property(pivot, "scale", Vector3.ONE, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# Use the actual locomotion playhead; preserve distance fallback for missing rig.
func _movement_audio(was_grounded: bool, distance: float) -> void:
	if not was_grounded or not is_on_floor() or _dash_left>0 or _hit_lock>0 or _attack_phase>0 or Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down")).length()<0.1 or distance<0.001:
		_step_distance=0.0
		_foot_contacts.reset()
		return
	if _hero_anim:
		var clip:=str(_hero_anim.current_animation)
		if _foot_contacts.CONTACTS.has(clip) and _hero_anim.is_playing():
			var phase:=_hero_anim.current_animation_position/_hero_anim.current_animation_length
			if crouching and _crouch_modifier:
				clip="crouch";phase=_crouch_modifier.gait_phase
			for side in _foot_contacts.advance(clip,phase):
				FX.play("footstep_metal_a" if side==0 else "footstep_metal_b",1.0,-16.0 if crouching else -10.0)
		else:_foot_contacts.reset()
		return
	_step_distance+=distance
	var stride:=1.0 if crouching else 1.8
	if _step_distance>=stride:
		_step_distance=fmod(_step_distance,stride)
		FX.play("footstep_metal_b" if _step_side else "footstep_metal_a",1.0,-16.0 if crouching else -10.0)
		_step_side=not _step_side

func _cache_crouched_blade_pose() -> void:
	# Skeleton modifiers restore source poses after evaluation. Capture the final
	# low pose while it is available, so hits/trails follow the visible blade.
	if _hero_skel and _blade_hand>=0:
		_crouched_blade_pose=_hero_skel.global_transform*_hero_skel.get_bone_global_pose(_blade_hand)
		_crouched_blade_valid=true
