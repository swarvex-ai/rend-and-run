extends CharacterBody3D
signal defeated(enemy: CharacterBody3D)
signal arm_severed(at:Vector3)
var encounter_id := ""
## Chaser-Gegner — P04r2: Aktivierungs-KI + sichtbare Test-Nahkampfwaffe.
## Idle -> Erkennen (Alert: Halten + Waffe heben) -> Verfolgen -> ankuendiger
## Windup-Hieb -> Swing-Trefferfenster -> Recovery. Schaden NUR im Swing-Fenster
## gegen Koerper-/Waffenreichweite in X UND Y — kein Dauer-Kontaktschaden,
## ein Sprung klar ueber die Hiebzone geht ohne Schaden (Playtest 02.10).
## Waffen-Socket: BoneAttachment an mixamorig_RightHand — Vertrag mit
## Herkunfts-/Uebergabedaten: docs/contract-chaser-weapon-socket.md (P15).
## Severance-Namensvertrag unveraendert: arm_left_severable / cap_shoulder_left /
## Bone sev_arm_left. Bones werden NIE entfernt.

@export var speed := 5.0
@export_enum("Raider", "Duelist", "Brute", "PulseGuard") var role := 0
@export var hp := 2
@export var territory_min_x := -10000.0
## Once it is chasing Rend it may follow him this far west of its territory (set by the
## route, short of the checkpoints, which stay safe). INF: no further than the territory.
var pursuit_min_x := INF

## West edge it keeps to now: the territory at rest, the pursuit line while engaged.
func _west_edge() -> float:
	return territory_min_x if _state in [IDLE, ALERT] else minf(territory_min_x, pursuit_min_x)
@export var touch_damage := 1
## Ranged guards (role 3) can carry a Meshy firearm instead of the pulse emitter
## (modules/combat/gun.gd SPECS key); they drop it when they fall.
@export var gun_kind := ""
var _gun: Node3D
## Riot shield (Meshy, asset_library/meshy/2026-10-24_shield): blocks light blows and
## bullets from the front; a heavy blow (combo finisher, thrown case, armour piercer) knocks
## it aside and leaves the robot open; after SHIELD_BREAKS such blows it falls off.
@export var shield := false
const SHIELD_BREAKS := 3
var _shield: Node3D
var _shield_open := 0.0             # s the shield stays knocked aside
var shield_breaks_left := SHIELD_BREAKS
var blocks := 0
var _taunted := false               # said its first line on contact
var _circling := false              # waiting its turn at weapon distance
var _leaking := false               # smoke/sparks once badly damaged
# Squad director orders (squad_director.gd): a point to move to while chasing (NAN = none).
var squad_goal_x := NAN
var squad_goal_z := NAN

# --- KI-/Kampf-Parameter [P04r2, Nutzer-Playtest 02.10] ---
const DETECT_X := 10.0              # Erkennung horizontal (m); sharper sensors, earlier pressure
const DETECT_Z := 2.5               # Korridor-Tiefe (m)
const ALERT_S := 0.25               # sichtbare Reaktion: kurz stehen + Waffe heben
const WINDUP_S := 0.5               # Telegraphie: Ausholen (leuchtend)
const SWING_S := 0.2                # Swing-Dauer
const SWING_CONTACT := 0.12         # Kontakt-Augenblick: EIN Treffercheck pro Hieb
const RECOVERY_S := 0.8             # offen, aber kein Hieb moeglich
const WEAPON_REACH := 1.45          # Chaser-Mittellinie -> Spieler-Mittellinie
# Floor strip depth: robots line up with Rend before they strike.
const STRIKE_DEPTH := 0.35          # |dz| allowed to start a melee attack
const HIT_DEPTH := 0.6              # |dz| a committed swing still connects
# Spacing (push-box): bodies never close below PUSH_GAP, a lunge stops at STRIKE_GAP
# (weapon distance) and after the blow the robot backs off to ENGAGE_GAP.
const PUSH_GAP := 1.0
const STRIKE_GAP := 1.3
const ENGAGE_GAP := 1.9
const PUSH_DEPTH := 0.6             # |dz| below which the two bodies count as facing
const DEPTH_MIN := -1.05
# Light humanoid strikes. blow = (forward, up, right) in the attacker's frame: the
# direction the weapon travels at contact, which drives Rend's reaction. low/high is the
# band above the attacker's soles the blow sweeps; depth is the |dz| it still connects.
# side: duck under it. overhead: cannot be ducked, back off. uppercut: comes up from
# below, back off. thrust: narrow, step aside in depth.
const STRIKES := {
	"slash": {"clip":"combat/slash_light", "blow":Vector3(1.0, -0.2, 0.0), "zone":"torso", "low":1.10, "high":1.55, "depth":0.6, "kind":"high"},
	"side": {"clip":"strikes/side", "blow":Vector3(0.5, -0.1, -1.0), "zone":"torso", "low":1.15, "high":1.6, "depth":0.6, "kind":"high"},
	"overhead": {"clip":"strikes/overhead", "blow":Vector3(0.4, -1.0, 0.0), "zone":"head", "low":0.3, "high":1.9, "depth":0.5, "kind":"heavy"},
	"uppercut": {"clip":"strikes/uppercut", "blow":Vector3(0.6, 1.0, 0.0), "zone":"head", "low":0.3, "high":1.7, "depth":0.5, "kind":"heavy"},
	"thrust": {"clip":"strikes/thrust", "blow":Vector3(1.0, 0.0, 0.0), "zone":"torso", "low":0.7, "high":1.5, "depth":0.25, "kind":"heavy"},
	# Unarmed (sentinel): punch combination and a short elbow. Only robots without a blade use these.
	"punch": {"clip":"combat/slash_light", "blow":Vector3(1.0, 0.1, 0.0), "zone":"head", "low":1.1, "high":1.75, "depth":0.55, "kind":"high", "unarmed":true},
	"elbow": {"clip":"combat/elbow", "blow":Vector3(0.6, -0.1, -0.8), "zone":"torso", "low":0.9, "high":1.6, "depth":0.5, "kind":"high", "unarmed":true},
}
const DEPTH_MAX := 1.25
const STRIKE_LOW := 0.3             # Unterkannte der Hiebzone ueber Chaser-Sohle
const STRIKE_HIGH := 1.05           # Oberkante: Sprung-Scheitel ~1.5 m klar drueber
const PLAYER_HEIGHT := 1.3          # Spieler-Kapsel (Hurtbox-Hoehe, main.tscn)

enum { IDLE, ALERT, CHASE, WINDUP, SWING, RECOVERY }

var _ranged_attack:=false
var _aim_point:=Vector3.ZERO
var shots_fired:=0
var _pulse_pack: Node3D
var _pulse_weapon: Node3D
var _attack_cue: Node3D
var _attack_front := 1.0
var _stun := 0.0
var _hit_recovering := false
var _attack_count := 0
var _guard_spacing = preload("res://modules/combat/guard_spacing.gd").new()
var _guard_retreat_front := 1.0
var _guard_was_retreating := false
var _recovery_step = preload("res://modules/combat/recovery_step.gd").new()
var _committed_low := false
var _spawn_x := 0.0
var _dead := false
var _death_physics: SkeletonModifier3D
var crouching: bool:
	get: return _dead or (_committed_low and _state in [WINDUP,SWING,RECOVERY])
var facing: float:
	get: return _front_sign()
var death_squash := false           # [t_bb2ba447] true ab Todes-Squash-Animation (Harness-Anker)
var _state := IDLE
var _state_t := 0.0
var _swing_hit := false             # EIN Treffer pro Swing
var _severed := false
var hits_taken := 0                 # [P04] Zaehlt Hiebe (Test: ein Treffer pro Ziel pro Hieb)
var _kb_timer := 0.0                # Knockback-Fenster: Chaser darf velocity nicht sofort schlucken
var _lane_offset := 0.0             # per-robot depth offset so pairs flank instead of stacking
var _heavy := false                 # heavy chassis model (brute role)
var _sidestep_t := 0.0              # stepping around a prop that blocks the chase
var _strike := "slash"              # current strike of a light humanoid (STRIKES key)
var forced_strike := ""             # tests/reviews pin one strike
var _sidestep_dir := 1.0
var _vault_t := 0.0                 # > 0 while hopping over a low obstacle
var vaults := 0                     # tests: obstacles cleared by hopping
const VAULT_MAX_HEIGHT := 0.8       # props lower than this are climbed over (a case), taller ones walked around
var _mechanical := false
var _chaser: Node3D
var _anim: AnimationPlayer
var _body_mesh: MeshInstance3D
var _arm_mesh: MeshInstance3D
var _cap_mesh: MeshInstance3D
var _skeleton: Skeleton3D
var _stance: SkeletonModifier3D
var _hit_overlay: SkeletonModifier3D  # upper-body mocap hit reaction (hit_overlay.gd)
var _hit_physics: SkeletonModifier3D  # physical hit reaction, same proxies as the death ragdoll
var _weapon_pivot: Node3D           # schwenkbarer Waffenarm (Telegraph + Swing)
var _weapon_mat: StandardMaterial3D

@onready var visual: MeshInstance3D = $VisualPivot/Visual

func _ready() -> void:
	set_meta("owns_melee_hit_audio", true)
	_lane_offset = float(get_instance_id() % 3 - 1) * 0.25
	collision_layer = 2
	collision_mask = 1 | 4  # world and Rend: robots cannot walk through him
	_spawn_x = position.x
	# Groesser als die 0,90m-Lieferung: gegen den 1,70m-Held sonst zu Witzfigur-massstab.
	$VisualPivot.scale = Vector3(1.7, 1.7, 1.7)
	# Kollision an neue Groesse anpassen (duplizieren: Szene teilt die Shape)
	var cs := $Collision as CollisionShape3D
	cs.shape = cs.shape.duplicate()
	cs.shape.size = Vector3(0.8, 1.5, 0.8)
	cs.position = Vector3(0, 0.75, 0)
	# Material klonen: Flash darf die geteilten Materials der anderen Gegner nicht treffen
	var base := visual.get_active_material(0)
	if base:
		visual.material_override = base.duplicate()
	_try_load_chaser()
	_attack_cue=preload("res://modules/vfx/enemy_attack_cue.gd").new()
	add_child(_attack_cue)
	if role == 2:
		hp = 3
		speed = 3.4
		$VisualPivot.scale *= 1.12
	elif role == 1:
		speed = 5.6
	var label := Label3D.new()
	if role==3:
		speed=3.8
	label.name = "RoleLabel"
	label.visible = false  # design aid only; roles read from silhouette and weapon
	label.text = ["RAIDER", "DUELLANT", "BRECHER", "IMPULSWACHE"][role]
	label.position.y = 2.15 if role == 2 else 1.9
	label.font_size = 24
	label.pixel_size = 0.006
	label.modulate = [Color(1,0.5,0.22), Color(0.2,0.9,1), Color(1,0.3,0.5),Color(0.1,0.85,1)][role]
	add_child(label)

func _try_load_chaser() -> void:
	# Vision 2.0: every opponent is a robot; only Rend bleeds.
	_mechanical = true
	# The brute is the heavy chassis (heavy industrial armour); the others the light humanoid.
	_heavy = role == 2
	var CHASER := "res://assets3d/characters/heavy_humanoid_v1/model.glb" if _heavy else "res://assets3d/characters/light_humanoid_severable_v1/model.glb"
	if not ResourceLoader.exists(CHASER):
		return  # Fallback: Platzhalter-Box bleibt sichtbar
	_chaser = load(CHASER).instantiate()
	if _mechanical and not _heavy:
		preload("res://modules/visuals/humanoid_surface_finish.gd").apply(_chaser)
	$VisualPivot.add_child(_chaser)
	if _mechanical:
		$VisualPivot.scale=Vector3.ONE
		_chaser.rotation.y=PI/2
	visual.visible = false
	# Modell-Front ist +X -> bei rotation.y=0 läuft der Chaser nach rechts. Passt.
	_skeleton = _chaser.find_child("Skeleton3D", true, false) as Skeleton3D
	_anim = _chaser.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_arm_mesh = _chaser.find_child("arm_left_severable", true, false) as MeshInstance3D
	_cap_mesh = _chaser.find_child("cap_shoulder_left", true, false) as MeshInstance3D
	if _cap_mesh: _cap_mesh.hide()
	_body_mesh = _chaser.find_child("char1" if _mechanical else "body", true, false) as MeshInstance3D
	if _anim:
		if _mechanical:
			var motion=preload("res://generated/light_humanoid_motion.tres")
			var locomotion=AnimationLibrary.new()
			for clip in ["walk","run"]:locomotion.add_animation(clip,motion.get_animation(clip))
			if _heavy:
				locomotion=AnimationLibrary.new()
				locomotion.add_animation("walk",preload("res://generated/heavy_walk.tres").get_animation("walk"))
				locomotion.add_animation("run",preload("res://generated/heavy_run.tres").get_animation("run"))
			if _anim.has_animation_library(""):_anim.remove_animation_library("")
			_anim.add_animation_library("",locomotion)
		for clip in ["walk", "run"]:
			if _anim.has_animation(clip):
				_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		_anim.add_animation_library("combat",preload("res://generated/heavy_combat.tres") if _heavy else preload("res://generated/light_humanoid_motion.tres"))
		# Meshy hit reactions retargeted onto this rig (tools/retarget_clips.gd), in place.
		_anim.add_animation_library("react",preload("res://generated/heavy_react.tres") if _heavy else preload("res://generated/robot_hit_motion.tres"))
		if not _heavy:_anim.add_animation_library("strikes",preload("res://generated/robot_strike_motion.tres"))
		_anim.play("combat/idle")
	_attach_weapon()
	if shield and ResourceLoader.exists("res://assets3d/weapons/riot_shield_v1/model.glb"):_build_shield()
	if role == 3 and _skeleton:
		_pulse_pack = preload("res://modules/visuals/pulse_pack.gd").attach(_skeleton, $VisualPivot)
	if _skeleton:
		_stance = preload("res://crouch_pose.gd").new()
		_stance.actor=self
		_skeleton.add_child(_stance)
		_hit_overlay = preload("res://modules/combat/hit_overlay.gd").new()
		_hit_overlay.arm_weight = 0.8
		_skeleton.add_child(_hit_overlay)
		_hit_physics = preload("res://modules/combat/hit_physics.gd").new()
		_hit_physics.actor = self
		_skeleton.add_child(_hit_physics)

# ---------------------------------------------------------------------------
# Guard equipment at the existing animated right-hand grip.
# Socket-/Griffvertrag fuer das finale Rig (P15): docs/contract-chaser-weapon-socket.md
# ---------------------------------------------------------------------------
func _attach_weapon() -> void:
	if _skeleton == null:
		return
	var hand := _skeleton.find_bone("RightHand" if _mechanical else "mixamorig_RightHand")
	if hand < 0:
		return
	# The source has an animated grip bone, crucial for its authored blade arc.
	var grip_bone:=_skeleton.add_bone("hand_r")
	_skeleton.set_bone_parent(grip_bone,hand)
	_skeleton.set_bone_rest(grip_bone,Transform3D(Basis(Vector3(0.070036,-0.990803,0.115778),Vector3(0.990228,0.055022,-0.128142),Vector3(0.120593,0.123621,0.984975)),Vector3(-0.001929,0.079955,0.019426)*0.5))
	if _mechanical:
		# Meshy skeleton uses centimetres; the attachment restores metre-sized props.
		_skeleton.set_bone_rest(grip_bone,Transform3D(Basis(Vector3(-51.45877,-84.07571,-16.83055),Vector3(54.33031,-47.15727,69.45791),Vector3(-66.33413,26.5981,69.94518)),Vector3(2.00111,7.047023,3.219158)))
	_skeleton.reset_bone_pose(grip_bone)
	var att := BoneAttachment3D.new()
	att.bone_name = "hand_r"
	_skeleton.add_child(att)
	var aim := Node3D.new()
	att.add_child(aim)
	_weapon_pivot = Node3D.new()
	aim.add_child(_weapon_pivot)
	var weapon: Node3D
	if role==0:weapon=preload("res://assets3d/weapons/security_baton_v1/model.glb").instantiate()
	elif role==2:weapon=preload("res://modules/visuals/brute_cleaver_visual.gd").new()
	elif role!=3:weapon=load("res://assets3d/weapons/hero_sword.glb").instantiate()
	if role==3 and not gun_kind.is_empty():
		weapon=preload("res://modules/combat/gun.gd").make(gun_kind)
		weapon.ammo=1000000  # robots never run dry
		_pulse_weapon=weapon;_gun=weapon
		if _anim:_anim.add_animation_library("gun",preload("res://generated/robot_gun_motion.tres"))
	elif role==3:
		weapon=preload("res://modules/visuals/pulse_emitter_visual.gd").new()
		_pulse_weapon=weapon
	weapon.name="WeaponBlade"
	weapon.scale=Vector3.ONE*0.58
	_weapon_pivot.add_child(weapon)
	if _gun:_normalize_gun.call_deferred()

# The hand attachment carries the Meshy rig's centimetre scale; the gun sizes itself in metres.
func _normalize_gun() -> void:
	if is_instance_valid(_gun):_gun.global_basis = _gun.global_basis.orthonormalized()

func _physics_process(delta: float) -> void:
	if _dead:
		if is_instance_valid(_death_physics):return
		# Keep the defeated body grounded while its knees/torso collapse. Combat
		# collision is removed in _die, but floor collision must keep working.
		velocity.y += get_gravity().y * 1.4 * delta
		velocity.x = move_toward(velocity.x, 0.0, (12.0 if is_on_floor() else 2.0) * delta)
		velocity.z = 0.0
		move_and_slide()
		return
	_kb_timer = maxf(0.0, _kb_timer - delta)
	_state_t += delta
	_stun = maxf(0.0, _stun - delta)
	velocity.y += get_gravity().y * 1.4 * delta

	var player: Node3D = get_tree().get_first_node_in_group("player")
	if player and not player._dying:
		var dx := player.global_position.x - global_position.x
		var dz := player.global_position.z - global_position.z
		if _state != CHASE or _stun > 0.0 or _kb_timer > 0.0:_cancel_guard_spacing()
		if _stun > 0.0:
			velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
			move_and_slide()
			return
		match _state:
			IDLE:
				_turn(player, delta)
				_hold(delta)
				if absf(dx) <= DETECT_X and absf(dz) <= DETECT_Z and absf(player.global_position.y-global_position.y) < 2.4:
					var sight:=PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.5,0),player.global_position+Vector3(0,1.5,0),1)  # eye height: over waist-high cover
					# Seen, or heard close by (a short dog behind cover still notices him).
					if get_world_3d().direct_space_state.intersect_ray(sight).is_empty() or Vector2(dx, dz).length() < 3.5: _enter(ALERT)
			ALERT:
				_turn(player, delta)
				_hold(delta)
				if _state_t >= ALERT_S:
					_enter(CHASE)
				elif absf(dx) > DETECT_X * 1.4:
					_enter(IDLE)      # ausser Sicht: calmiert zurueck
			CHASE:
				if _guard_was_retreating and not _guard_spacing.is_active():velocity.x=0.0
				if not _guard_spacing.is_active():_turn(player, delta)
				var reach := 2.1 if role == 0 else 2.35 if role == 1 else 2.2 if role == 2 else 1.55
				var desired := signf(dx) * speed
				_circling = false
				# A gunner Rend closes on backs off to keep its range.
				if role == 3 and absf(dx) < 2.4 and global_position.x - signf(dx) * 0.5 > _west_edge():desired = -signf(dx) * speed * 0.8
				var retreat := _guard_retreat_velocity(dx, delta) if role == 3 else 0.0
				var retreating := _guard_spacing.is_active() or not is_zero_approx(retreat)
				_guard_was_retreating = retreating
				if retreating:
					desired = retreat
				elif role==3 and absf(dx)>2.5 and absf(dx)<=6.0:
					desired=0.0
					# A squad mate in the line of fire: hold fire while stepping aside (squad_director).
					if not is_finite(squad_goal_z) and _can_attack() and _has_fire_lane(player) and _claim_attack_onset():
						_ranged_attack=true;_aim_point=_chest(player)
						_enter(WINDUP)
				elif is_finite(squad_goal_x):
					# Flanking or clearing a line of fire: head for the director's point; close to
					# Rend it first moves off his lane, then passes.
					desired = clampf((squad_goal_x - global_position.x) * 4.0, -speed, speed)
					if is_finite(squad_goal_z) and absf(squad_goal_z - global_position.z) > 0.35 and absf(dx) < 1.8:desired = 0.0
				elif absf(dx) <= reach and _reach_clear(player):
					desired = 0.0
					if absf(dz) <= _strike_depth() and _can_attack() and absf(player.global_position.y-global_position.y) < 1.8 and _claim_attack_onset():
						_ranged_attack=false
						_enter(WINDUP)
					elif absf(dz) > _strike_depth() and is_on_wall() and absf(dx) > 0.8:
						# Wrong depth and something (a cover's corner) stops the step across: edge
						# forward past it first.
						desired = signf(dx) * speed * 0.6
					else:
						# Not its turn: stalk him - hold weapon distance and circle in depth.
						_circling = true
						if absf(dx) < ENGAGE_GAP - 0.2:desired = -signf(dx) * speed * 0.35
				for other in get_tree().get_nodes_in_group("enemies"):
					if retreating:break
					if other == self or other._dead:
						continue
					var gap: float = global_position.x-other.global_position.x
					# Only robots sharing a depth lane crowd each other; a flanker passes on its own lane.
					if absf(gap) < 1.05 and absf(global_position.z-other.global_position.z) < 0.5:
						desired += (signf(gap) if absf(gap)>0.05 else (1.0 if get_instance_id()>other.get_instance_id() else -1.0)) * 2.8
				if _kb_timer <= 0.0:
					velocity.x = desired if retreating else move_toward(velocity.x, desired, 24.0 * delta)
					# Close in on Rend's depth; a small per-robot offset keeps pairs from stacking.
					var lane_gap := dz + _lane_offset * clampf(absf(dx) / 3.0, 0.0, 1.0)
					if is_finite(squad_goal_z):lane_gap = squad_goal_z - global_position.z
					elif _circling:lane_gap = dz + sin(_state_t * 1.7 + float(get_instance_id() % 7)) * 0.55
					else:
						# A squad mate standing in my lane between me and Rend: overtake it on another lane.
						var blocker := _lane_blocker(dx)
						if blocker:
							var pass_side := 1.0 if blocker.global_position.z < 0.1 else -1.0
							lane_gap = blocker.global_position.z + pass_side * 0.75 - global_position.z
					# Something solid ahead in this lane (cases, props): take the nearest clear lane.
					# (A gunner in firing range holds Rend's lane: it is not walking on anyway.)
					if not is_finite(squad_goal_z) and not (role == 3 and absf(dx) <= 6.0):
						var clear_z := _clear_lane(signf(dx), global_position.z + lane_gap, delta)
						if is_finite(clear_z):lane_gap = clear_z - global_position.z
					# Melee robots take Rend's lane quickly (stepping aside buys him a moment, no more);
					# gunners shoot across the lanes and move in depth calmly.
					var z_rate := 3.0 if role == 3 else 4.5
					var z_cap := speed * (0.7 if role == 3 else 0.9)
					velocity.z = move_toward(velocity.z, clampf(lane_gap * z_rate, -z_cap, z_cap), 20.0 * delta)
					if _sidestep_t > 0.0:velocity.z = _sidestep_dir * speed * 0.8
				if absf(dx) > DETECT_X * 1.7:
					_enter(IDLE)
			WINDUP:
				# Acquire during early charge, then commit for the final 300ms.
				# This is aiming before launch, never a homing projectile.
				if _ranged_attack and _state_t < 0.55 and dx * _attack_front > 0.1:
					_aim_point = _chest(player)
				if _ranged_attack and _attack_cue:
					_attack_cue.set_ranged_locked(_state_t >= 0.55)
				# Announce outside Rend's close range, then physically step into reach.
				# Direction was committed on entry: dodging behind still makes it miss.
				if not _ranged_attack and role in [1,2] and _state_t>=_lunge_start() and _kb_timer<=0 and absf(dx)>STRIKE_GAP:
					velocity.x=move_toward(velocity.x,_attack_front*(3.2 if role==1 else 2.8),30.0*delta)
				else:_hold(delta)
				if _state_t >= _windup_duration():
					_enter(SWING)
			SWING:
				velocity.x = _attack_front * (6.0 if role == 0 else 1.2) if _state_t < 0.12 and absf(dx) > STRIKE_GAP else move_toward(velocity.x, 0, 40*delta)
				# Klinge trifft kurz nach Swing-Beginn; spaetter im Fenster laeuft sie aus.
				if not _swing_hit and _state_t >= 0.075 and _state_t <= 0.15:
					if _ranged_attack:
						_swing_hit=true
						_fire_energy(player)
					else:_try_swing_hit(player, dx, dz)
				if _state_t >= SWING_S:
					_enter(RECOVERY)
			RECOVERY:
				_hold(delta)
				# First 120ms remain stationary and punishable; then a short fixed retreat.
				if role==1 and _state_t >= 0.12 and _kb_timer<=0:
					velocity.x = _recovery_step.advance(delta)
				elif role in [0,2] and not _ranged_attack and _state_t >= 0.12 and _kb_timer<=0 and absf(dx) < ENGAGE_GAP and absf(dz) < PUSH_DEPTH:
					velocity.x = move_toward(velocity.x, -signf(dx) * speed * 0.6, 20.0 * delta)  # back off to weapon distance
				if _state_t >= _recovery_duration():
					_enter(CHASE)
	else:
		_cancel_guard_spacing()
		_hold(delta)
	_keep_push_gap(delta)
	# Stop at ledges: no endless running into a pit or through level walls.
	if is_on_floor() and absf(velocity.x) > 0.1:
		var ahead := global_position + Vector3(signf(velocity.x)*0.65, 0.3, 0)
		# Only a real drop counts; stepping down off a case it climbed is fine.
		var q := PhysicsRayQueryParameters3D.create(ahead, ahead + Vector3(0,-2.6,0), 1)
		if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			velocity.x = 0.0
			_recovery_step.cancel()
			_cancel_guard_spacing()
	if global_position.x<=_west_edge()+0.05 and velocity.x<0 and _kb_timer<=0:velocity.x=0
	if _pulse_weapon:_pulse_weapon.set_charge(clampf(_state_t/0.85,0,1) if _state==WINDUP and _ranged_attack and _stun<=0 else 0.0)
	_update_weapon_pose(delta)
	_update_shield(delta)
	if _state != CHASE or _stun > 0.0:velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	move_and_slide()
	if global_position.z < DEPTH_MIN or global_position.z > DEPTH_MAX:
		global_position.z = clampf(global_position.z, DEPTH_MIN, DEPTH_MAX);velocity.z = 0.0
	_sidestep_t = maxf(0.0, _sidestep_t - delta)
	_vault_t = maxf(0.0, _vault_t - delta)
	# Loose cases it runs into are shoved out of the way, as Rend does.
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider() as RigidBody3D
		if body and not body.freeze and absf(hit.get_normal().y) < 0.5:
			body.apply_central_impulse(-hit.get_normal() * minf(5.0, speed * 0.9))
	# Climb only from the floor (never onto a stack) and not as a gunner, which keeps its distance.
	if is_on_wall() and is_on_floor() and global_position.y < 0.3 and role != 3 and _state == CHASE and _vault_t <= 0.0 and absf(get_wall_normal().x) > 0.6 and _obstacle_is_low():
		# A case or low prop in the way: climb over it in a hop, as a person would.
		_vault_t = 0.45;vaults += 1
		velocity.y = 5.8
		velocity.x = -signf(get_wall_normal().x) * maxf(absf(velocity.x), speed * 0.7)
	elif is_on_wall() and _state == CHASE and _sidestep_t <= 0.0 and _vault_t <= 0.0 and absf(get_wall_normal().x) > 0.6:
		# A prop blocks the chase: step around it in depth, toward Rend's side when he has one.
		var target := get_tree().get_first_node_in_group("player") as Node3D
		var dz := target.global_position.z - global_position.z if target else 0.0
		_sidestep_dir = signf(dz) if absf(dz) > 0.15 else (1.0 if global_position.z < DEPTH_MAX - 0.6 else -1.0)
		_sidestep_t = 0.5
	if is_on_wall():
		_recovery_step.cancel()
		_cancel_guard_spacing()

## Alerted from outside (alarm, a squad mate's radio call): skips the slow wake-up.
func _voice() -> Node:
	return get_tree().get_first_node_in_group("robot_voice")

func provoke() -> void:
	if _dead or _state not in [IDLE, ALERT]:return
	_enter(CHASE)

func _enter(s: int) -> void:
	_cancel_guard_spacing()
	var missed_swing := _state == SWING and not _swing_hit and not _ranged_attack
	_recovery_step.cancel()
	_hit_recovering=false
	_state = s
	_state_t = 0.0
	if s == WINDUP:
		_attack_front = _front_sign()
		_attack_count += 1
		_committed_low = _next_attack_is_low()
		_strike = _choose_strike()
		if _attack_cue:
			var kind:=_attack_kind()
			_attack_cue.begin(_attack_front,kind,_windup_duration())
	elif _attack_cue:_attack_cue.cancel()
	if s == CHASE and not _taunted and _voice():
		_taunted = _voice().say(self, "taunt")
	if s == SWING:
		_swing_hit = false
		if not _ranged_attack:FX.play("swing",0.65,-6.0)
	if s == RECOVERY and role == 1 and missed_swing and _stun<=0 and _kb_timer<=0:
		_recovery_step.start(_attack_front)
	if _anim:
		_anim.speed_scale=1.0
		match s:
			IDLE, ALERT:
				_anim.play("combat/idle",0.12)
			CHASE:
				_anim.play("run",0.12)
			WINDUP:
				_anim.play(_strike_clip(),0.0)
				_anim.advance(0)
				_anim.speed_scale=0.0

func _turn(player: Node3D, delta: float) -> void:
	var dx := player.global_position.x - global_position.x
	var dz := player.global_position.z - global_position.z
	# Face left/right, leaning toward Rend's depth without flipping the attack front.
	var front := -1.0 if dx < 0.0 else 1.0
	var lean := clampf(-dz / maxf(absf(dx), 0.6), -0.7, 0.7) * front
	$VisualPivot.rotation.y = lerp_angle($VisualPivot.rotation.y, (PI if dx < 0.0 else 0.0) + lean, 15.0 * delta)

## Push-box: a robot facing Rend in depth never stands closer than PUSH_GAP; it gives way.
func _keep_push_gap(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player or _kb_timer > 0.0 or collision_layer & 2 == 0:return
	if is_finite(squad_goal_z):return  # passing him off his lane
	var dx := player.global_position.x - global_position.x
	if absf(dx) >= PUSH_GAP or absf(player.global_position.z - global_position.z) >= PUSH_DEPTH:return
	var away := -signf(dx) if absf(dx) > 0.01 else -_front_sign()
	if velocity.x * away < 3.0:velocity.x = move_toward(velocity.x, away * 3.0, 60.0 * delta)

var _lane_probe_t := 0.0
var _clear_z := NAN
const LANES := [-0.95, -0.6, -0.25, 0.1, 0.45, 0.8, 1.15]
# Probes the next 1.4 m along the chase in the wanted lane; if props block it, returns the
# nearest lane (to the wanted one) that is clear, else NAN (no change). Re-checked 5x a second.
func _clear_lane(dir: float, wanted_z: float, delta: float) -> float:
	_lane_probe_t -= delta
	if _lane_probe_t > 0.0:return _clear_z
	_lane_probe_t = 0.2
	if _lane_free(dir, wanted_z):
		_clear_z = NAN
		return NAN
	var best := NAN;var best_d := INF
	for z in LANES:
		if absf(z - wanted_z) < best_d and _lane_free(dir, z):best = z;best_d = absf(z - wanted_z)
	_clear_z = best
	return best

func _lane_free(dir: float, z: float) -> bool:
	var shape := BoxShape3D.new();shape.size = Vector3(0.7, 1.2, 0.7)
	var q := PhysicsShapeQueryParameters3D.new();q.shape = shape;q.collision_mask = 1;q.exclude = [get_rid()]
	q.transform = Transform3D(Basis.IDENTITY, Vector3(global_position.x, global_position.y + 0.75, clampf(z, DEPTH_MIN, DEPTH_MAX)))
	q.motion = Vector3(dir * 1.4, 0, 0)
	var result := get_world_3d().direct_space_state.cast_motion(q)
	return result.size() == 2 and result[0] >= 0.99

# Nothing solid (cover, cases) between me and Rend at knee and chest height? Otherwise a
# melee robot keeps moving - around the obstacle on a clear lane - instead of swinging at it.
func _reach_clear(player: Node3D) -> bool:
	var space := get_world_3d().direct_space_state
	for h in [0.4, 1.0]:
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, h, 0), player.global_position + Vector3(0, h, 0), 1, [get_rid(), player.get_rid()])
		if not space.intersect_ray(q).is_empty():return false
	return true

# Clear above knee height in front of me? Then the obstacle can be vaulted.
func _obstacle_is_low() -> bool:
	var ahead := -signf(get_wall_normal().x)
	var from := global_position + Vector3(0, VAULT_MAX_HEIGHT + 0.05, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(ahead * 1.0, 0, 0), 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

# The nearest squad mate in my depth lane between me and Rend (within 1.6 m), if any.
func _lane_blocker(dx: float) -> Node3D:
	var best: Node3D = null;var best_gap := 1.6
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or other._dead or not other is Node3D:continue
		var gap: float = (other.global_position.x - global_position.x) * signf(dx)
		if gap <= 0.0 or gap > best_gap or gap > absf(dx):continue
		if absf(other.global_position.z - global_position.z) > 0.5:continue
		best = other;best_gap = gap
	return best

func _hold(delta: float) -> void:
	if _kb_timer <= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)

func _front_sign() -> float:
	# Modell-Front ist +X; rotation.y ~0 -> front=+1, ~PI -> front=-1
	return 1.0 if absf(wrapf($VisualPivot.rotation.y, -PI, PI)) < PI / 2.0 else -1.0

func swing_hits_at(dx: float, dz: float, rel_feet: float, front: float) -> bool:
	# Reine Treffer-Geometrie [P04r2], damit der Harness X/Y ohne Physik-Framing
	# pruefen kann. X: nur innerhalb Waffenreichweite VOR der Front — keine
	# Treffer allein wegen gleicher X-Position. Y: Fussdifferenz gegen Band
	# [STRIKE_LOW - PLAYER_HEIGHT, STRIKE_HIGH): der Sprungscheitel (~1.5 m) ist
	# klar drueber, Bodenkontakt und Fallen IN der Zone treffen weiter.
	if absf(dz) > HIT_DEPTH:
		return false
	if dx * front <= 0.0 or absf(dx) > WEAPON_REACH:
		return false
	return rel_feet < STRIKE_HIGH and rel_feet + PLAYER_HEIGHT > STRIKE_LOW

func _try_swing_hit(player: Node3D, dx: float, dz: float) -> void:
	# Schaden NUR im Swing-Fenster — kein Dauer-Kontaktschaden.
	if _swing_hit or not player.has_method("take_damage"):
		return
	var rel_feet := player.global_position.y - global_position.y
	var height: float = player.hurt_height() if player.has_method("hurt_height") else PLAYER_HEIGHT
	var strike: Dictionary = STRIKES[_strike]
	var low: float = 0.05 if _committed_low else strike.low
	var high: float = 0.55 if _committed_low else strike.high
	if absf(dz)>strike.depth or dx*_attack_front<=0.0 or absf(dx)>_weapon_reach() or rel_feet>=high or rel_feet+height<=low:
		return
	var q := PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1,0), player.global_position+Vector3(0,height*0.5,0), 1)
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return
	_swing_hit = true
	FX.play("hit", 0.7, -6.0)
	FX.add_shake(0.25)
	player.take_damage(touch_damage, global_position, self)

func _claim_attack_onset() -> bool:
	var scene := get_tree().current_scene
	return scene.claim_enemy_attack(global_position.x) if is_instance_valid(scene) and scene.has_method("claim_enemy_attack") else true

func _can_attack() -> bool:
	var target:=get_tree().get_first_node_in_group("player") as Node3D
	if target and target.global_position.x<_west_edge():return false
	var director := get_tree().get_first_node_in_group("squad_director")
	if director and not director.may_attack(self):return false
	var occupied := 0
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or other._dead:
			continue
		if other._state in [WINDUP, SWING] and absf(other.global_position.x-global_position.x)<8.0:
			occupied += 1
	return occupied < 2

func _update_weapon_pose(_delta: float) -> void:
	if not _anim or _stun>0: return
	if _hit_recovering:
		if not _anim.is_playing():_anim.play("combat/idle",0.1)
		return
	if role==3 and _ranged_attack and _state in [WINDUP,SWING,RECOVERY]:
		# Aim: the pulse emitter is held out by the slash pose, a gun in both hands (Meshy shooting clip).
		if _gun and _anim.has_animation("gun/walk_shoot"):
			_anim.play("gun/walk_shoot",0.0);_anim.speed_scale=0.0;_anim.seek(0.3,true)
		else:
			_anim.play("combat/slash_light",0.0);_anim.speed_scale=0.0;_anim.seek(0.55,true)
		_anim.advance(0)
		_aim_emitter()
		return
	if _pulse_weapon:_pulse_weapon.rotation=Vector3.ZERO
	if role==3 and _state==CHASE and _guard_spacing.is_active() and absf(velocity.x)>0.1:
		if _anim.assigned_animation!="walk":_anim.play("walk",0.06,-1.0,true)
		_anim.speed_scale=0.9
		return
	if _state==RECOVERY and role==1 and _recovery_step.is_active() and _state_t>=0.12 and absf(velocity.x)>0.1:
		if _anim.assigned_animation!="walk":_anim.play("walk",0.06,-1.0,true)
		_anim.speed_scale=0.9
		return
	# Synchronize the whole body to readable attack phases, not a floating weapon pivot.
	var clip_time: float=-1.0
	match _state:
		WINDUP:
			var duration: float=_windup_duration()
			clip_time=lerpf(0.0,0.30,clampf(_state_t/duration,0,1))
		SWING:
			clip_time=lerpf(0.30,0.55,clampf(_state_t/SWING_S,0,1))
		RECOVERY:
			clip_time=lerpf(0.55,0.85,clampf(_state_t/_recovery_pose_duration(),0,1))
	if clip_time>=0:
		if _anim.assigned_animation!=_strike_clip():
			_anim.play(_strike_clip(),0.0)
			_anim.speed_scale=0.0
		_anim.speed_scale=0.0
		_anim.seek(clip_time,true)
		_anim.advance(0)
	elif _state==CHASE:
		# Walking sideways in depth counts too, or it would glide while circling.
		# Real motion, not the wish: pressing against a door or a case it stands, not marches.
		var real:=get_real_velocity()
		var ground:=Vector2(real.x,real.z).length()
		var moving:=ground>0.3
		var clip: String=("run" if ground>2.6 or not _anim.has_animation("walk") else "walk") if moving else "combat/idle"
		if _anim.current_animation!=clip:_anim.play(clip,0.12)
		_anim.speed_scale=clampf(ground/(4.0 if clip=="run" else 1.6),0.65,1.3) if moving else 1.0

func debug_reset_ai() -> void:
	_guard_spacing.reset()
	_recovery_step.cancel()
	if _attack_cue:_attack_cue.cancel()
	# Test-Harness [P04]: KI zurueck in den Spawn-Zustand (Idle)
	_state = IDLE
	_state_t = 0.0
	_swing_hit = false
	velocity = Vector3.ZERO

func take_melee_hit(damage: int, knockback: Vector3) -> void:
	if _dead:
		return
	if _shield_covers(knockback):
		if knockback.y > 2.5 or damage >= 2:_shield_broken(knockback)
		else:_shield_block(knockback)
		return
	# A heavy cleaver already in its committed downswing has momentum. It still
	# takes full damage and can die; early anticipation and parries interrupt it.
	var continuing_reaction:=_state==RECOVERY and _hit_recovering
	var committed:=_has_attack_momentum()
	hits_taken += 1
	hp -= damage
	var heavy:=knockback.y>2.5 or damage>=2
	var shocked:=damage>=2 and _mechanical
	if committed and hp>0:
		velocity.x=knockback.x*0.15
		_kb_timer=0.08
	else:
		# A metal body absorbs the blow: a short shove, the upper body sells the impact.
		velocity.x=signf(knockback.x)*(2.6 if heavy else 1.3)
		velocity.y=minf(velocity.y,0.0)
		_kb_timer = 0.16
		# Repeated hits keep their impact but cannot restart the full recovery clock.
		# Preserve a longer parry stun instead of shortening it with the follow-up.
		_stun = maxf(_stun,(0.5 if shocked else 0.28) if role != 2 else 0.18)
		if not continuing_reaction:_enter(RECOVERY)
		_hit_recovering=true
		if _anim:
			var clip := _reaction_clip(heavy,shocked)
			if shocked or not is_instance_valid(_hit_overlay) or not clip.begins_with("react/"):
				_anim.play(clip,0.06,1.3)  # electrocution shakes the whole frame
			else:
				# Legs keep their stance (no sliding feet); spine, head and arms take the blow.
				_anim.play("combat/idle",0.08)
				_hit_overlay.play(_anim.get_animation(clip), 1.3 if heavy else 1.0)
			if is_instance_valid(_hit_physics):
				_hit_physics.strike("head" if not heavy and _react_index == 1 else "torso", Vector3(signf(knockback.x) * (2.6 if heavy else 1.8), 0.25, 0.0))
	_flash()
	FX.play("hit", 1.15, -2.0)
	var contact:=global_position+Vector3(-signf(knockback.x)*0.2,1.15 if not heavy else 0.95,0.25)
	if shocked:FX.shock(contact,knockback)
	elif _mechanical:FX.robot_impact(contact,Vector3(knockback.x,0.6,0),heavy)
	else:FX.blood(global_position + Vector3(0, 1.4, 0), 26, 4.5, Vector3(knockback.x, maxf(1.2, knockback.y), 0))
	if hp == 1 and _voice():_voice().say(self, "damage")
	if hp > 0 and hp <= 1 and not _leaking and _skeleton and _mechanical:
		# Badly damaged: smoke and sparks leak from the chest from now on.
		_leaking = true
		var chest := BoneAttachment3D.new();chest.bone_name = "Spine";_skeleton.add_child(chest)
		var mount := Node3D.new();chest.add_child(mount);mount.top_level = false
		preload("res://modules/vfx/gun_fx.gd").damage_leak(mount)
	if hp <= 0:
		_die(knockback)
	elif not _severed and knockback.y > 2.5:
		# A committed countercut may sever the arm; ordinary touches do not.
		_sever_arm()

var _react_index := 0
func _reaction_clip(heavy: bool, shocked: bool) -> String:
	if not _anim.has_animation_library("react"):return "combat/hit_react"
	if shocked:return "react/stun_shock"
	if heavy:return "react/hit_body"
	# Successive light hits vary: chest jolt, head snap, short flinch.
	_react_index=(_react_index+1)%3
	return ["react/hit_light","react/hit_head","react/hit_front"][_react_index]

func _sever_arm() -> void:
	if _arm_mesh == null or _severed:
		return
	_severed = true
	_arm_mesh.visible = false                    # Cap wird sichtbar statt Chirurgie
	if _cap_mesh:
		_cap_mesh.visible = true
	var socket_pos := global_position + Vector3(0, 0.7, 0)
	if _skeleton and _skeleton.find_bone("sev_arm_left") >= 0:
		var bone_idx: int = _skeleton.find_bone("sev_arm_left")
		socket_pos = _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_idx).origin
	if _mechanical:
		FX.metal_contact(socket_pos, Vector3(velocity.x, 2.0, 0))
	else:
		FX.blood(socket_pos, 34, 5.5, Vector3(velocity.x, 2.0, 0))
		FX.pool(global_position)
	_spawn_severed_arm(socket_pos)
	arm_severed.emit(socket_pos)

func _spawn_severed_arm(at: Vector3) -> void:
	var STUB := "res://assets3d/characters/light_humanoid_arm_v1/model.glb" if _mechanical else "res://assets3d/characters/enemy_chaser_arm_left_severable.glb"
	if not ResourceLoader.exists(STUB):
		return
	var arm: Node3D = load(STUB).instantiate()
	if _mechanical:
		preload("res://modules/visuals/humanoid_surface_finish.gd").apply(arm)
	var body := RigidBody3D.new()
	body.add_child(preload("res://modules/combat/debris_pause.gd").new())
	body.name = "DetachedRobotArm" if _mechanical else "DetachedArm"
	body.collision_layer = 0
	body.collision_mask = 1                       # Deko: soll nicht zurueckballeln
	body.mass = 0.5
	body.add_child(arm)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.16, 0.5, 0.16)
	col.shape = box
	body.add_child(col)
	get_tree().current_scene.add_child(body)
	body.global_transform = Transform3D($VisualPivot.global_basis, at)
	if _mechanical and _skeleton:
		# The static export is in metre-scaled model space, rooted at the cut.
		# Apply the current upper-arm rotation without inheriting the rig's 0.01 scale.
		var upper := _skeleton.find_bone("LeftArm")
		var delta := _skeleton.get_bone_global_pose(upper).basis * _skeleton.get_bone_global_rest(upper).basis.inverse()
		body.global_basis = (_skeleton.global_basis * delta).orthonormalized()
		var mesh := arm.find_child("severed_robot_arm", true, false) as MeshInstance3D
		if mesh == null and arm is MeshInstance3D: mesh = arm
		if mesh:
			var bounds: AABB = body.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
			box.size = bounds.size.max(Vector3.ONE * 0.06)
			col.position = bounds.get_center()
			body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			body.center_of_mass = col.position
	body.linear_velocity = Vector3(velocity.x*0.3, 0.7, 0.2)
	body.angular_velocity = Vector3(0.5, 1.2, -signf(velocity.x)*2.5)
	get_tree().create_timer(8.0, false).timeout.connect(body.queue_free)

# A brief white overlay over every surface (its own materials stay untouched); sparks,
# hitstop and the body reaction carry the impact.
var _flash_mat: StandardMaterial3D
func _flash() -> void:
	var mesh: GeometryInstance3D = _body_mesh if _body_mesh else visual
	if mesh == null:return
	if _flash_mat == null:
		_flash_mat = StandardMaterial3D.new();_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;_flash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_flash_mat.albedo_color = Color(1, 1, 1, 0.55)
	mesh.material_overlay = _flash_mat
	var tw := create_tween()
	tw.tween_property(_flash_mat, "albedo_color:a", 0.0, 0.1)
	tw.tween_callback(func(): if is_instance_valid(mesh) and mesh.material_overlay == _flash_mat: mesh.material_overlay = null)

func _die(knockback := Vector3.ZERO) -> void:
	_cancel_guard_spacing()
	_recovery_step.cancel()
	if _attack_cue:_attack_cue.cancel()
	_dead = true
	if _stance:_stance.collapse=true
	defeated.emit(self)
	if has_node("RoleLabel"): $RoleLabel.hide()
	_drop_weapon(knockback)
	_drop_shield(knockback)
	if _mechanical:
		# It comes apart: a shower of plating, servos and cable; a hard blow takes the head off.
		var scene := get_tree().current_scene
		var debris := preload("res://modules/vfx/debris.gd")
		debris.breakup(scene, global_position + Vector3(0, 1.0, 0), Vector3(signf(knockback.x), 0.4, 0), 30 if knockback.y > 2.0 else 22)
		FX.robot_impact(global_position + Vector3(0, 1.2, 0.1), Vector3(signf(knockback.x), 0.6, 0), true)
		if _skeleton and (knockback.y > 2.0 or randf() < 0.35):
			var head := _skeleton.find_bone("Head")
			if head >= 0:
				var head_at := _skeleton.global_transform * _skeleton.get_bone_global_pose(head).origin
				_skeleton.set_bone_pose_scale(head, Vector3.ONE * 0.001)
				set_meta("head_off", true)  # the death ragdoll leaves it off
				debris.head(scene, head_at + Vector3(0, 0.1, 0), Vector3(signf(knockback.x), 0, 0))
	if is_instance_valid(_pulse_pack): _pulse_pack.drop(knockback)
	if knockback.y > 2.5 and _body_mesh:
		var pieces:int=preload("res://death_fragments.gd").burst(self, _body_mesh, knockback)
		if pieces>0:
			_body_mesh.hide()
			if _arm_mesh:_arm_mesh.hide()
			if _cap_mesh:_cap_mesh.hide()
	if _mechanical and _body_mesh and _body_mesh.visible:
		_start_articulated_death.call_deferred(knockback)
	death_squash = true                 # [t_bb2ba447] Harness-Anker: Squash-Track wird gestartet
	FX.add_shake(0.45)
	if _mechanical:FX.metal_contact(global_position+Vector3(0,1.1,0),knockback,true)
	else:
		FX.blood(global_position + Vector3(0, 1.4, 0), 40, 6.0, Vector3(knockback.x, maxf(1.5, knockback.y), 0))
		FX.pool(global_position)
	FX.play("die", 1.15, -2.0)
	if _anim:
		_anim.speed_scale=0.0
	# Stop blocking the player/projectiles without dropping the world collider.
	# Disabling this shape used to freeze launched deaths above the floor.
	collision_layer = 0
	remove_from_group("enemies")
	# Keep a short-lived physical aftermath; the stance solver remains the fallback.
	var tw := create_tween()
	tw.tween_interval(6.0 if _mechanical else 2.4)
	tw.tween_callback(queue_free)

func _start_articulated_death(impulse: Vector3) -> void:
	# Build outside the physics query that delivered the hit. Capture the current
	# rig pose; skins, arm visibility and all original bones remain untouched.
	if not is_instance_valid(_skeleton) or is_instance_valid(_death_physics):return
	if is_instance_valid(_hit_physics) and _hit_physics.is_reacting():_hit_physics.physics_root.queue_free()
	var modifier=preload("res://modules/combat/articulated_death.gd").new()
	_skeleton.add_child(modifier)
	if not modifier.build(self,impulse):
		modifier.queue_free()
		return
	_death_physics=modifier
	if _stance:_stance.active=false
	$Collision.disabled=true
	velocity=Vector3.ZERO

func _drop_weapon(impulse: Vector3) -> void:
	if _weapon_pivot == null: return
	if _gun:
		# The gun falls to the floor as a pickup Rend can take, with a fresh magazine.
		_weapon_pivot.hide()
		preload("res://modules/combat/gun_pickup.gd").drop(get_tree().current_scene, global_position + Vector3(_front_sign() * 0.6, 0, 0), gun_kind, preload("res://modules/combat/gun.gd").SPECS[gun_kind].ammo * 2)  # a magazine and a spare
		return
	var original := _weapon_pivot.global_transform
	var debris := RigidBody3D.new()
	debris.add_child(preload("res://modules/combat/debris_pause.gd").new())
	debris.add_to_group("dropped_weapons")
	debris.collision_layer=0
	debris.collision_mask=1
	debris.mass=1.4
	debris.angular_damp=1.0
	var visual_copy := _weapon_pivot.duplicate() as Node3D
	debris.add_child(visual_copy)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(0.14,0.464,0.065) if role==3 else Vector3(0.16,0.61,0.05) if role==2 else Vector3(1.2,0.15,0.15)
	col.shape=box
	col.position=Vector3(0,0.174,0) if role==3 else Vector3(0,0.2465,0) if role==2 else Vector3(0.6,0,0)
	if role==3 and _pulse_weapon:
		col.basis=_pulse_weapon.basis.orthonormalized()
		col.position=_pulse_weapon.position+col.basis*col.position
	debris.add_child(col)
	get_tree().current_scene.add_child(debris)
	debris.global_transform=Transform3D(original.basis.orthonormalized(),original.origin)
	visual_copy.transform=Transform3D(Basis.from_scale(original.basis.get_scale()),Vector3.ZERO)
	debris.linear_velocity=Vector3(impulse.x*0.15,0.2,0.15)
	debris.angular_velocity=Vector3(0,0.4,-signf(impulse.x)*2)
	_weapon_pivot.hide()
	get_tree().create_timer(5.0, false).timeout.connect(debris.queue_free)

func _shield_raised() -> bool:
	return is_instance_valid(_shield) and _stun <= 0.0 and _shield_open <= 0.0 and _state not in [WINDUP, SWING]

# A blow from the front (knockback points away from the attacker) meets the raised shield.
func _shield_covers(knockback: Vector3) -> bool:
	return _shield_raised() and signf(knockback.x) == -_front_sign()

func _shield_block(knockback: Vector3) -> void:
	blocks += 1
	if blocks == 1 and _voice():_voice().say(self, "hold_line")
	var at := _shield.global_position + Vector3(0, 0.1, 0.1)
	FX.metal_contact(at, Vector3(-signf(knockback.x), 0.5, 0))
	FX.play("block", 0.9, -3.0);FX.add_shake(0.12)
	velocity.x = signf(knockback.x) * 1.4;_kb_timer = 0.12
	# The attacker bounces off the shield.
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player and absf(player.global_position.x - global_position.x) < 2.5:
		player.velocity.x = -signf(knockback.x) * 3.5

func _shield_broken(knockback: Vector3) -> void:
	shield_breaks_left -= 1
	FX.play("guard_break", 1.0, -2.0);FX.hitstop(0.07);FX.add_shake(0.35)
	FX.robot_impact(_shield.global_position, Vector3(signf(knockback.x), 0.6, 0), true)
	_stun = 0.7;_shield_open = 1.0;_hit_recovering = true
	velocity.x = signf(knockback.x) * 2.5;_kb_timer = 0.16
	if _state != RECOVERY:_enter(RECOVERY)
	if shield_breaks_left <= 0:_drop_shield(knockback)

func _drop_shield(impulse: Vector3) -> void:
	if not is_instance_valid(_shield):return
	# Knocked off or let go as it falls: the shield lands on the floor where Rend can take it.
	preload("res://modules/combat/shield_pickup.gd").drop(get_tree().current_scene, global_position + Vector3(signf(impulse.x) * 0.7, 0, 0.2), "riot")
	_shield.queue_free();_shield = null

func _build_shield() -> void:
	var model := preload("res://assets3d/weapons/riot_shield_v1/model.glb").instantiate() as Node3D
	_shield = Node3D.new();_shield.name = "RiotShield";add_child(_shield);_shield.top_level = true
	# Meshy shield: ~1.9 m model, face toward +Z; scale to 1.05 m tall and turn its face forward.
	var box := AABB();var first := true
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.transform * m.get_aabb();box = b if first else box.merge(b);first = false
	var s := 1.05 / maxf(box.size.y, 0.001)
	_shield.add_child(model);model.scale = Vector3.ONE * s;model.position = -box.get_center() * s

# Held on the left forearm in front of the body; swung aside while it strikes or is knocked open.
func _update_shield(delta: float) -> void:
	_shield_open = maxf(0.0, _shield_open - delta)
	if not is_instance_valid(_shield) or _skeleton == null:return
	var hand := _skeleton.find_bone("LeftHand")
	var front := _front_sign()
	var at := global_position + Vector3(front * 0.45, 1.0, 0.1)
	if hand >= 0:at = (_skeleton.global_transform * _skeleton.get_bone_global_pose(hand).origin).lerp(at, 0.5)
	var raised := _shield_raised()
	var turn := (0.0 if raised else 1.1) * front
	var forward := Vector3(front, 0, 0).rotated(Vector3.UP, turn)
	if not raised:at += Vector3(-front * 0.25, -0.15, 0.25)
	var target := Transform3D(Basis.looking_at(-forward, Vector3.UP), at)
	_shield.global_transform = _shield.global_transform.interpolate_with(target, minf(1.0, 16.0 * delta))

func receive_parry() -> void:
	_cancel_guard_spacing()
	_recovery_step.cancel()
	if _dead:return
	if _attack_cue:_attack_cue.cancel()
	_stun=0.65
	_hit_recovering=true
	_swing_hit=true
	_state=RECOVERY
	_state_t=0.0
	velocity.x=-_attack_front*3.0
	if _anim and _anim.has_animation("combat/hit_react"):
		_anim.speed_scale=1.0
		_anim.play("combat/hit_react",0.04)

# A gunner fires across the depth lanes: stepping aside does not hide Rend, only cover does
# (crouching behind it puts his chest under its edge).
func _has_fire_lane(player: Node3D) -> bool:
	if player.global_position.x<_west_edge() or absf(player.global_position.y-global_position.y)>1.8:return false
	var q:=PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.2,0),_chest(player),1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

# Where a gunner aims: the middle of Rend's chest, standing or crouched, in his depth lane.
func _chest(player: Node3D) -> Vector3:
	var height: float = player.hurt_height() if player.has_method("hurt_height") else PLAYER_HEIGHT
	return player.global_position + Vector3(0, height * 0.7, 0)

func _fire_energy(player: Node3D) -> void:
	if _dead or _stun>0 or not _has_fire_lane(player):return
	_aim_emitter()
	var origin:Vector3=_pulse_weapon.get_node("Muzzle").global_position if _pulse_weapon else global_position+Vector3(_attack_front*0.65,1.2,0)
	var direction:=(_aim_point-origin).normalized()
	if direction.x*_attack_front<=0:return
	var muzzle_ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.2,0),origin,1)
	if not get_world_3d().direct_space_state.intersect_ray(muzzle_ray).is_empty():return
	if _gun:
		_fire_gun_burst(direction)
		return
	var bolt=preload("res://modules/combat/energy_bolt.gd").new()
	get_tree().current_scene.add_child(bolt)
	bolt.lifetime=2.5
	bolt.set_meta("incoming",direction)
	var impact = preload("res://modules/combat/energy_impact.gd").new()
	impact.configure(self, _west_edge(), direction, _attack_front)
	bolt.add_child(impact)
	bolt.impacted.connect(impact.resolve)
	bolt.launch(origin,direction*8.0,5,[get_rid()])
	get_tree().create_timer(2.6, false).timeout.connect(bolt.queue_free)
	shots_fired+=1
	FX.play("swing",1.7,-6.0)

# Each gun has its own pattern: pistol double tap, SMG burst, one scatter blast, rifle salvo.
func _fire_gun_burst(direction: Vector3) -> void:
	var spec: Dictionary = _gun.spec()
	for i in int(spec.burst):
		if _dead or _stun > 0 or not is_instance_valid(_gun):return
		_gun._cooldown = 0.0
		if _gun.fire(direction, 1 | 4, self, [get_rid()]):shots_fired += 1
		if i < int(spec.burst) - 1:await get_tree().create_timer(spec.interval, false).timeout

func _aim_emitter() -> void:
	if not is_instance_valid(_pulse_weapon):return
	var forward:=(_aim_point-_pulse_weapon.global_position).normalized()
	if forward.length_squared()<0.1:return
	if _gun:
		# Barrel (+Y) at the target, top of the gun (+X) up.
		var top:=(Vector3.UP-forward*Vector3.UP.dot(forward)).normalized()
		_gun.global_basis=Basis(top,forward,top.cross(forward))
		return
	var side:=forward.cross(Vector3.BACK).normalized()
	if side.length_squared()<0.1:return
	var depth:=side.cross(forward).normalized()
	var world_scale:=_pulse_weapon.global_basis.get_scale()
	_pulse_weapon.global_basis=Basis(side,forward,depth).scaled(world_scale)

# Environmental pressure interruption is independent of damage and severance.
func interrupt_with_pressure(origin: Vector3) -> void:
	if _dead:return
	_enter(RECOVERY)
	_recovery_step.cancel()
	_stun = maxf(_stun, 0.55)
	_kb_timer = 0.18
	velocity.x = signf(global_position.x - origin.x) * 2.0
	_hit_recovering = true
	if _pulse_weapon:_pulse_weapon.set_charge(0.0)
	if _anim and _anim.has_animation("combat/hit_react"):
		_anim.speed_scale = 1.0
		_anim.play("combat/hit_react", 0.05)

func _cancel_guard_spacing() -> void:
	_guard_was_retreating = false
	_guard_spacing.advance(0.0, 1.0, false, 0.01)

func _guard_retreat_velocity(dx: float, delta: float) -> float:
	if not _guard_spacing.is_active():_guard_retreat_front = _front_sign()
	var front := _guard_retreat_front
	var eligible := _state == CHASE and _stun <= 0 and _kb_timer <= 0 and is_on_floor() and dx * front > 0
	if eligible:
		var remaining := maxf(0.02, 0.7 - _guard_spacing.distance_traveled()) if _guard_spacing.is_active() else 0.7
		var move := Vector3(-front * remaining, 0, 0)
		var ahead := global_position + move + Vector3(0, 0.3, 0)
		var ray := PhysicsRayQueryParameters3D.create(ahead, ahead + Vector3(0,-1.1,0), 1)
		eligible = ahead.x >= _west_edge() and not test_move(global_transform, move) and not get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	return _guard_spacing.advance(absf(dx), front, eligible, delta)

# Overridable attack decisions. Defaults preserve the four existing enemy roles.
func _next_attack_is_low() -> bool:
	return role == 1 and _attack_count % 2 == 0

func _attack_kind() -> String:
	return "ranged" if _ranged_attack else "heavy" if role==2 else "low" if _committed_low else STRIKES[_strike].kind

# Light humanoids vary their blows; nobody repeats the same one twice running.
func _choose_strike() -> String:
	if _heavy or role > 1 or _ranged_attack or _committed_low or not _anim or not _anim.has_animation_library("strikes"):
		return "slash"
	if forced_strike in STRIKES:return forced_strike
	var unarmed := _fights_unarmed()
	var options := STRIKES.keys().filter(func(k): return k != _strike and STRIKES[k].get("unarmed", false) == unarmed)
	return options[randi() % options.size()]

func _fights_unarmed() -> bool:
	return false

func _strike_clip() -> String:
	return STRIKES[_strike].clip

# World direction the weapon travels at contact, and the body zone it lands on.
func blow_vector() -> Vector3:
	if _ranged_attack:return Vector3(_attack_front, 0, 0)
	var b: Vector3 = STRIKES[_strike].blow
	if _committed_low:b = Vector3(0.6, 0.0, 0.0)
	var forward := Vector3(_attack_front, 0, 0)
	return (forward * b.x + Vector3.UP * b.y + forward.cross(Vector3.UP) * b.z).normalized()

func blow_zone() -> String:
	return "legs" if _committed_low else "torso" if _ranged_attack or role == 2 else STRIKES[_strike].zone

# Read by Rend to pick a matching pain reaction.
func attack_kind() -> String:
	return _attack_kind()

func _weapon_reach() -> float:
	return WEAPON_REACH

# |dz| within which it starts a melee attack.
func _strike_depth() -> float:
	return STRIKE_DEPTH

func _windup_duration() -> float:
	return 0.85 if _ranged_attack else 0.64 if role==2 else 0.40 if role==1 else 0.44

func _recovery_duration() -> float:
	return 1.1 if _ranged_attack else 0.62 if role==2 else 0.32 if role==1 else 0.40

func _recovery_pose_duration() -> float:
	return 0.48

func _commit_time() -> float:
	return 0.34

func _lunge_start() -> float:
	return 0.10 if role==1 else 0.28

func _has_attack_momentum() -> bool:
	return role==2 and ((_state==WINDUP and _state_t>=_commit_time()) or _state==SWING)
