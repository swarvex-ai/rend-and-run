extends Node
## Squad director: makes the robots fight as a team instead of one by one.
## - Radio: a robot that engages Rend calls every idle robot within RADIO_RANGE (audible chirp).
## - Pincer: the second melee robot circles past Rend in depth and attacks from his other side.
## - Rhythm: only one melee robot winds up at a time; the next may start once that blow lands,
##   so attacks interlock (pressure) yet each stays readable.
## - Fire discipline: gunners never shoot through a squad mate; they sidestep in depth instead.
## - Evasion: duelists sometimes hop back out of a swing they see coming.
## Robots ask may_attack() before a windup and follow squad_goal_x/z while chasing (enemy.gd).
## Group "squad_director".

const RADIO_RANGE := 12.0
const RADIO_DELAY := 0.35
const ENGAGE_RANGE := 14.0
const FLANK_DISTANCE := 1.9
const PASS_DEPTH := 0.85        # how far off Rend's lane a flanker passes him
const DODGE_CHANCE := 0.3

var player: Node3D
var _called := {}               # robot -> true once it has radioed
var _flankers := {}             # robot -> side (+1/-1 of Rend) it is circling to
var _pending := []              # [time_left, robot]
var _last_rend_attack := 0
var calls := 0                  # tests: radio calls made
var flank_orders := 0           # tests: pincer goals handed out
var dodges := 0

func _ready() -> void:
	add_to_group("squad_director")

func _robots() -> Array:
	var result := []
	for e in get_tree().get_nodes_in_group("enemies"):
		# Frozen robots (scripted scenes, tests) are not part of the squad.
		if e.has_method("provoke") and not e._dead and e.is_physics_processing():result.append(e)
	return result

static func _engaged(e) -> bool:
	return e._state in [e.CHASE, e.WINDUP, e.SWING, e.RECOVERY]

static func _melee(e) -> bool:
	return e.role != 3 and not e._ranged_attack

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player._dying:return
	var robots := _robots()
	_radio(robots, delta)
	_pincer(robots)
	_fire_discipline(robots)
	_evade(robots)

func _radio(robots: Array, delta: float) -> void:
	for e in robots:
		if not _engaged(e):
			_called.erase(e)  # calms down: it will radio again on the next contact
			continue
		if _called.has(e):continue
		_called[e] = true
		var any := false
		for other in robots:
			if other == e or _engaged(other):continue
			if absf(other.global_position.x - e.global_position.x) < RADIO_RANGE and absf(other.global_position.x - player.global_position.x) < ENGAGE_RANGE + 2.0:
				_pending.append([RADIO_DELAY, other]);any = true
		if any:
			calls += 1
			FX.play("radio_chirp", 1.0, -10.0)
			var voice := get_tree().get_first_node_in_group("robot_voice")
			if voice:voice.say(e, "converge")
	for item in _pending.duplicate():
		item[0] -= delta
		if item[0] <= 0.0:
			_pending.erase(item)
			if is_instance_valid(item[1]) and not item[1]._dead:item[1].provoke()

func _pincer(robots: Array) -> void:
	var melee := []
	for e in robots:
		e.squad_goal_x = NAN;e.squad_goal_z = NAN
		if _engaged(e) and _melee(e) and e.role != 2 and absf(e.global_position.x - player.global_position.x) < ENGAGE_RANGE:melee.append(e)
	for e in _flankers.keys():
		if not is_instance_valid(e) or not e in melee:_flankers.erase(e)
	if melee.size() < 2:
		_flankers.clear()
		return
	# Sticky roles: the robot not circling and nearest Rend holds the front; one other circles
	# to his far side and keeps that order until it gets there.
	var holders := melee.filter(func(e): return not _flankers.has(e))
	holders.sort_custom(func(a, b): return absf(a.global_position.x - player.global_position.x) < absf(b.global_position.x - player.global_position.x))
	if holders.is_empty():return
	var front_side := signf(holders[0].global_position.x - player.global_position.x)
	if _flankers.is_empty():
		for e in holders.slice(1):
			if signf(e.global_position.x - player.global_position.x) == front_side and e._state == e.CHASE:
				_flankers[e] = -front_side
				var voice := get_tree().get_first_node_in_group("robot_voice")
				if voice:voice.say(e, "flank")
				break
	for e in _flankers.keys():
		var flank: float = _flankers[e]
		var goal_x: float = player.global_position.x + flank * FLANK_DISTANCE
		if goal_x < e.territory_min_x or signf(e.global_position.x - player.global_position.x) == flank:
			_flankers.erase(e);continue  # arrived (it now attacks from there) or no room behind him
		if e._state != e.CHASE:continue
		e.squad_goal_x = goal_x
		# Pass him off his lane, then close in behind.
		var passing: bool = absf(e.global_position.x - player.global_position.x) < 2.6
		var away := PASS_DEPTH if player.global_position.z < 0.1 else -PASS_DEPTH
		e.squad_goal_z = player.global_position.z + (away if passing else 0.0)
		flank_orders += 1

## Rhythm: one melee wind-up at a time; gunners take turns.
func may_attack(e) -> bool:
	for other in _robots():
		if other == e or other._state != other.WINDUP:continue
		if _melee(other) == (e.role != 3) and absf(other.global_position.x - player.global_position.x) < ENGAGE_RANGE:return false
	return true

func _fire_discipline(robots: Array) -> void:
	for gunner in robots:
		if gunner.role != 3 or not _engaged(gunner):continue
		for mate in robots:
			if mate == gunner or not _melee(mate):continue
			var between: bool = (mate.global_position.x - gunner.global_position.x) * (player.global_position.x - mate.global_position.x) > 0.0
			# Shots run diagonally across the lanes: where does the line pass the mate?
			var t: float = clampf((mate.global_position.x - gunner.global_position.x) / (player.global_position.x - gunner.global_position.x), 0.0, 1.0) if between else 0.0
			var line_z: float = lerpf(gunner.global_position.z, player.global_position.z, t)
			if between and absf(mate.global_position.z - line_z) < 0.5:
				# A squad mate is in the line of fire: step aside in depth.
				gunner.squad_goal_x = gunner.global_position.x
				gunner.squad_goal_z = clampf(mate.global_position.z + (0.75 if mate.global_position.z < 0.1 else -0.75), -1.0, 1.2)
				break

func _evade(robots: Array) -> void:
	var swing_started: bool = player._attack_phase == 1 and player._attack_elapsed < 0.05
	if not swing_started:
		_last_rend_attack = 0
		return
	if _last_rend_attack == 1:return
	_last_rend_attack = 1
	for e in robots:
		if e.role != 1 or e._state not in [e.CHASE, e.RECOVERY] or e._stun > 0.0:continue
		var dx: float = e.global_position.x - player.global_position.x
		if absf(dx) > 1.9 or dx * player.facing <= 0.0 or absf(e.global_position.z - player.global_position.z) > 0.6:continue
		if randf() > DODGE_CHANCE:continue
		e.velocity.x = signf(dx) * 6.5;e._kb_timer = 0.2
		dodges += 1
		FX.play("swing", 1.4, -12.0)
