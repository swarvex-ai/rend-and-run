extends "res://enemy.gd"
## P28 greybox: authored two-height encounter, using the existing Brute asset.
## Entry gate closes after full admission; death/defeat releases it.
var UI_TEXT = load("res://data/ui_texts.gd")
const MAX_HP := 12
const ADMISSION_X := preload("res://modules/world/notstrom_layout.gd").BOSS_ENTRY_X
var active := false
var _brace_hits := 0
var _braced_attack := false
var phase := 1
var _phase_attack := 0
var _home := Vector3(preload("res://modules/world/notstrom_layout.gd").BOSS_X,0.05,0)

func _ready() -> void:
	role = 2
	super._ready()
	if _skeleton:
		var low_pose = preload("res://modules/combat/overseer_low_pose.gd").new()
		low_pose.actor = self
		_skeleton.add_child(low_pose)
	hp = MAX_HP
	territory_min_x = ADMISSION_X
	get_node("RoleLabel").text = UI_TEXT.t("overseer_role")

func _physics_process(delta: float) -> void:
	if _dead:return
	var target := get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(target) or target._dying:return
	if target.global_position.x < ADMISSION_X:
		if active:reset_encounter()
		return
	if not active:
		active = true
		_enter(ALERT)
	super._physics_process(delta)

func _next_attack_is_low() -> bool:
	# Latch the phase only at the next tell; damage never changes a committed hit.
	var next_phase := 2 if hp <= MAX_HP / 2 else 1
	if next_phase != phase:
		phase = next_phase
		_phase_attack = 0
	_phase_attack += 1
	return _phase_attack % 2 == 0 if phase == 1 else _phase_attack % 3 != 2

func _attack_kind() -> String:
	return "low" if _committed_low else "high"

func _windup_duration() -> float:
	return 0.70 if _committed_low else 0.80

func _recovery_duration() -> float:
	return 0.90

func _recovery_pose_duration() -> float:
	return _recovery_duration()

func _commit_time() -> float:
	return _windup_duration() - 0.30

func _lunge_start() -> float:
	# Longer anticipation must not accidentally produce a longer lunge.
	return _windup_duration() - 0.36

func take_melee_hit(damage: int, knockback: Vector3) -> void:
	if not active:return
	if damage>0 and not _braced_attack:_brace_hits+=1
	super.take_melee_hit(damage,knockback)

func reset_encounter() -> void:
	if _dead:return
	active = false
	_brace_hits=0;_braced_attack=false
	hp = MAX_HP
	phase = 1
	_phase_attack = 0
	_attack_count = 0
	_committed_low = false
	_ranged_attack = false
	_stun = 0.0
	_kb_timer = 0.0
	_severed = false
	if _arm_mesh:_arm_mesh.show()
	if _cap_mesh:_cap_mesh.hide()
	global_position = _home
	velocity = Vector3.ZERO
	_enter(IDLE)

func _enter(s: int) -> void:
	if s==WINDUP:_braced_attack=_brace_hits>=2
	elif s==RECOVERY and _state==SWING:
		_brace_hits=0;_braced_attack=false
	super._enter(s)
	var label=get_node_or_null("RoleLabel")
	if label:
		label.text=UI_TEXT.t("overseer_braced") if _braced_attack and s in [WINDUP,SWING] else UI_TEXT.t("overseer_role")
		label.modulate=Color(1,.7,.2) if _braced_attack else Color(1,.3,.5)

func _has_attack_momentum() -> bool:
	return (_braced_attack and _state in [WINDUP,SWING]) or super._has_attack_momentum()

func receive_parry() -> void:
	_brace_hits=0;_braced_attack=false
	super.receive_parry()
	var label=get_node_or_null("RoleLabel")
	if label:label.text=UI_TEXT.t("overseer_role");label.modulate=Color(1,.3,.5)
