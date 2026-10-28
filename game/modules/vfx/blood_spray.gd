extends Node3D
## H62: tapered droplets follow velocity and shrink out.
## H18 world-space emission, burst bounds and cleanup remain unchanged.

const MAX_BURSTS := 8
const CLEANUP_DELAY := 1.5     # Sekunden; Partikel-Lifetime <= 0.9s bleibt sichtbar
const SPREAD_DEG := 25.0
const GRAVITY := Vector3(0.0, -18.0, 0.0)
const LIFETIME_MIN := 0.65
const LIFETIME_MAX := 0.9

static var _droplet_mesh: ArrayMesh = null
static var _droplet_material: StandardMaterial3D = null
static var _shrink_curve: Curve = null
static func _ring_pos(ring_idx: int, i: int, n: int, rings: Array) -> Vector3:
	var a := TAU * float(i) / float(n)
	return Vector3(cos(a) * float(rings[ring_idx]["r"]), float(rings[ring_idx]["y"]), sin(a) * float(rings[ring_idx]["r"]))

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_normal((b - a).cross(c - a).normalized())
	st.add_vertex(a); st.add_vertex(c); st.add_vertex(b) # Godot clockwise front faces, outward normal above

static func _shared_mesh() -> ArrayMesh:
	if _droplet_mesh != null:
		return _droplet_mesh
	# Spindelfoermiger Tropfen entlang +Y: Kopf(apex) -> breiter Ring (0.0125 r)
	# -> Taille -> schmaler Heckring -> Heckspitze. 5 Segmente, flach shaded.
	# Hoehe 0.06 m (y -0.03..0.03), volle Breite 0.025 m. 30 Dreiecke.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 5
	var rings := [
		{"y": 0.012, "r": 0.0125},   # breiteste Stelle, nahe Kopf
		{"y": -0.006, "r": 0.0090},  # Taille
		{"y": -0.022, "r": 0.0035},  # Heckring
	]
	var head := Vector3(0.0, 0.03, 0.0)
	var tail := Vector3(0.0, -0.03, 0.0)
	for i in n:
		_tri(st, head, _ring_pos(0, (i + 1) % n, n, rings), _ring_pos(0, i, n, rings))
	for r in rings.size() - 1:
		for i in n:
			var a0 := _ring_pos(r, i, n, rings); var a1 := _ring_pos(r, (i + 1) % n, n, rings)
			var b0 := _ring_pos(r + 1, i, n, rings); var b1 := _ring_pos(r + 1, (i + 1) % n, n, rings)
			_tri(st, a0, a1, b1)
			_tri(st, a0, b1, b0)
	var last := rings.size() - 1
	for i in n:
		_tri(st, _ring_pos(last, i, n, rings), _ring_pos(last, (i + 1) % n, n, rings), tail)
	_droplet_mesh = st.commit()
	_droplet_mesh.resource_name = "BloodDropletH62"
	return _droplet_mesh

static func _shared_material() -> StandardMaterial3D:
	if _droplet_material == null:
		_droplet_material = StandardMaterial3D.new()
		_droplet_material.albedo_color = Color(0.35, 0.02, 0.04)  # dunkles Karmesin
		_droplet_material.roughness = 0.9
		_droplet_material.metallic = 0.0
		_droplet_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_droplet_material.emission_enabled = false
		_droplet_material.shadow_to_opacity = false
	return _droplet_material

static func _shrink() -> Curve:
	# Shrink-out ueber Lebensdauer: volle Groesse bis ~45%, dann auf ~15% rampen.
	if _shrink_curve == null:
		_shrink_curve = Curve.new()
		_shrink_curve.add_point(Vector2(0.0, 1.0))
		_shrink_curve.add_point(Vector2(0.45, 0.95))
		_shrink_curve.add_point(Vector2(0.8, 0.45))
		_shrink_curve.add_point(Vector2(1.0, 0.15))
	return _shrink_curve

var _active: Array = []  # [{gen, particles, timer}, ...] aeltester zuerst
var _generation: int = 0

# Startet einen One-Shot-Burst. world_pos/direction sind WELTKoordinaten/-richtung;
# direction (0,0,0) faellt auf Welt-UP zurueck. Der uebergebene Vektor bleibt unveraendert.
func emit_burst(world_pos: Vector3, direction: Vector3, strength: float = 1.0) -> void:
	while _active.size() >= MAX_BURSTS:
		var oldest: Dictionary = _active.pop_front()
		var old: CPUParticles3D = oldest["particles"]
		if is_instance_valid(old):
			old.emitting = false
			old.queue_free()
		_free_timer(oldest)
	var s := clampf(strength, 0.25, 2.0)
	var t := (s - 0.25) / 1.75  # 0..1
	var dir := direction.normalized() if direction.length_squared() > 0.0 else Vector3.UP

	var p := CPUParticles3D.new()
	p.name = "BloodBurst"
	p.one_shot = true
	p.emitting = false
	p.amount = int(round(lerpf(24.0, 48.0, t)))
	p.lifetime = LIFETIME_MIN + (LIFETIME_MAX - LIFETIME_MIN) * randf()
	p.lifetime_randomness = 0.0
	p.preprocess = 0.0
	p.explosiveness = 1.0
	p.local_coords = false
	p.mesh = _shared_mesh()          # echtes Tropfen-Mesh (geteilt, unveraendlich)
	p.material_override = _shared_material()
	p.visible = true
	# Verified Godot CPUParticles3D property; do not silently skip alignment.
	p.particle_flag_align_y = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
	p.direction = dir  # normierte WELT-Richtung (Basis bleibt IDENTITY)
	p.spread = SPREAD_DEG
	p.gravity = GRAVITY
	p.initial_velocity_min = 2.0 * s  # Vertrag: 2*s .. 5*s, s = clamp(strength,.25,2)
	p.initial_velocity_max = 5.0 * s
	p.angular_velocity_min = 0.0      # kein Taumeln
	p.angular_velocity_max = 0.0
	p.angle_min = 0.0
	p.angle_max = 0.0
	p.scale_amount_min = 0.8          # moderate Groessenstreuung
	p.scale_amount_max = 1.25
	p.scale_amount_curve = _shrink()
	p.damping_min = 0.0
	p.damping_max = 0.0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

	add_child(p)
	p.top_level = true
	p.global_transform = Transform3D(Basis.IDENTITY, world_pos)
	p.emitting = true
	p.restart()

	_generation += 1
	var timer := Timer.new()
	timer.wait_time = CLEANUP_DELAY
	timer.one_shot = true
	timer.autostart = true
	var entry := {"gen": _generation, "particles": p, "timer": timer}
	timer.timeout.connect(_retire.bind(entry))
	add_child(timer)
	_active.append(entry)

func clear() -> void:
	while not _active.is_empty():
		var entry: Dictionary = _active.pop_front()
		var p: CPUParticles3D = entry["particles"]
		if is_instance_valid(p):
			p.emitting = false
			p.queue_free()
		_free_timer(entry)

func active_count() -> int:
	return _active.size()

func _retire(entry: Dictionary) -> void:
	_free_timer(entry)
	for i in _active.size():
		if _active[i] == entry:
			_active.remove_at(i)
			var p: CPUParticles3D = entry["particles"]
			if is_instance_valid(p):
				p.emitting = false
				p.queue_free()
			return

func _free_timer(entry: Dictionary) -> void:
	var t = entry.get("timer")
	if t != null and is_instance_valid(t):
		t.queue_free()
