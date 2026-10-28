extends Node3D
## H44 — Standalone directional attack cue (visual replacement for the
## floating "!/TIEF/SCHWER" Label3D in fx.gd attack_warning).
## Attach as child of an enemy (or place at its origin). Pure local mesh
## geometry: no lights, no physics, no external textures, no text.
##
## API:
##   begin(facing: float, kind: String, duration: float)
##     facing: +1.0 (attack toward +X) or -1.0 (toward -X).
##     kind:   "high" | "low" | "heavy" | "ranged"; unknown -> no-op, hidden.
##     duration: seconds the cue stays readable, then fades by itself.
##   cancel() -> immediately invisible, resets for the next begin.
##
## Design: a short chevron a hand's width in FRONT of the enemy (it does NOT
## track the player), flat on the XY plane so the side-on 2.5D camera at +Z
## always sees it. Heights: high Y=1.25, low Y=0.35 (contract); heavy Y=0.95
## (cleaver torso line), ranged Y=1.25 (muzzle line). Colors: heavy warm
## copper, ranged cyan, high/low muted amber like the old telegraph.
##
## Node budget: root + pivot + 2 arm meshes = 4 nodes, built once in _init.
## Repeated begin() reuses the same nodes (no growth); it restarts the fade
## window (generation-guarded tween, no per-frame _process).

const OFFSET_X := 0.55        # chevron tip distance in front of the enemy
const HEIGHTS := {"high": 1.25, "low": 0.35, "heavy": 0.95, "ranged": 1.25}
const COLORS := {
	"high": Color(1.0, 0.78, 0.3),
	"low": Color(1.0, 0.62, 0.22),
	"heavy": Color(0.85, 0.42, 0.14),   # warm copper
	"ranged": Color(0.10, 0.80, 0.85),  # cyan
}

var _pivot: Node3D
var _mat: StandardMaterial3D
var _tween: Tween
var _gen := 0
var _kind := ""

func _init() -> void:
	name = "EnemyAttackCue"
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var arm_size := Vector3(0.20, 0.045, 0.04)
	_pivot = Node3D.new()
	_pivot.name = "Chevron"
	add_child(_pivot)
	for i in 2:
		var mi := MeshInstance3D.new()
		mi.name = "Arm%d" % i
		var bm := BoxMesh.new()
		bm.size = arm_size
		mi.mesh = bm
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var s := 1.0 if i == 0 else -1.0
		mi.rotation.z = 0.7 * s
		# chevron apex sits at the pivot and points +X (attack direction);
		# both arms sweep backward (-X) and spread +-Y, flat in XY for +Z cam
		mi.position = Vector3(-0.1 * cos(0.7), -0.1 * sin(0.7) * s, 0.0)
		_pivot.add_child(mi)
	_pivot.visible = false

func begin(facing: float, kind: String, duration: float) -> void:
	if not HEIGHTS.has(kind):
		cancel()   # unknown kind: show nothing, never spam
		return
	_kind = kind
	_pivot.scale = Vector3.ONE
	_gen += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null
	_mat.albedo_color = Color(COLORS[kind], 1.0)  # full alpha at cue start
	_pivot.rotation.z = 0.0 if facing >= 0.0 else PI
	_pivot.position = Vector3(OFFSET_X * (1.0 if facing >= 0.0 else -1.0), HEIGHTS[kind], 0.55)
	_pivot.visible = true
	var hold := maxf(duration, 0.15) * 0.8
	var fade := maxf(duration, 0.15) - hold
	if is_inside_tree():
		_tween = create_tween()
		_tween.tween_interval(hold)
		_tween.tween_property(_mat, "albedo_color:a", 0.0, fade)
		var gen_at_start := _gen
		_tween.tween_callback(_auto_hide.bind(gen_at_start))

func set_ranged_locked(locked: bool) -> void:
	if _kind != "ranged" or not _pivot.visible:return
	_mat.albedo_color = Color(Color(0.95,1.0,1.0) if locked else COLORS["ranged"], _mat.albedo_color.a)
	_pivot.scale = Vector3.ONE * (1.2 if locked else 1.0)

func cancel() -> void:
	_kind = ""
	_pivot.scale = Vector3.ONE
	_gen += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null
	_mat.albedo_color = Color(1, 1, 1, 1)   # reset for the next cue
	_pivot.visible = false

func _auto_hide(gen_at_start: int) -> void:
	if gen_at_start == _gen:
		_pivot.visible = false

func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
