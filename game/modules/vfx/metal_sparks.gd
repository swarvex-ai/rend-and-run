extends Node3D
# H24 — Begrenzte sichtbare Metallfunken (Ziel: res://modules/vfx/metal_sparks.gd).
# Vertrag: outputs/worker_contracts/H24-metal-sparks.txt (Codex, 06.10.2026).
# - Standalone Node3D ohne class_name. API:
#     emit_contact(world_position, direction, parry=false), clear(), active_count().
# - Warm-weiss/amber Kurzfunken fuer Schwert-auf-Metall (Block/Parry, Metallkiste);
#   Parry-Variante kuehleres blasses Zyan und leicht groesserer Burst (18 statt 10).
# - EXPLIZITES schmales Low-Poly-Mesh BoxMesh(0.012, 0.04, 0.012); unshaded
#   emissives Material; Alpha-Fade ueber color_ramp (Gradient.colors) via
#   vertex_color_use_as_albedo. KEINE Lights, keine Fullscreen-Glares, keine
#   langen Bahnen (kurze Lifetime).
# - GLOBALE BASIS IDENTITY (top_level), Weltposition = Vorgabe; Richtung
#   normalisiert, Zero-Fallback (0,1,0); Cone 35°; Velocity 2..5;
#   Gravity (0,-12,0); Lifetime 0.12..0.25s.
# - Zwei gecachte Materialien (normal/parry). Max 6 Bursts — vor dem siebten
#   retiret der aelteste inkl. SEINES Timers. Timer werden bei Timeout, Retire
#   UND clear explizit queue_free't (H18/H19-Lektion: one_shot stoppt nur).
# - Gesamt-Cleanup spaetestens 0.5s inkl. Timer; clear() = sofort active 0;
#   stale Timer ungefaehrlich (Token-Check). Kein Damage/Audio/FileIO/Physics/
#   Collision/Per-Frame-Logik.

const MAX_BURSTS := 6
const CLEANUP_DELAY := 0.45         # s; Vertrag: Gesamt-Cleanup <= 0.5s
const CONE_DEG := 35.0
const GRAVITY := Vector3(0.0, -12.0, 0.0)
# Ein-Burst-Spielwert: Partikel sterben vor dem 0.45s-Timer,
# damit der Gesamt-Cleanup (Knoten weg) spaetestens 0.5s braucht.
const LIFETIME_SPAN := 0.25
const SPEED_MIN := 2.0
const SPEED_MAX := 5.0
const AMOUNT_NORMAL := 10
const AMOUNT_PARRY := 18
const FALLBACK_DIR := Vector3(0.0, 1.0, 0.0)

# Geteilte, intern nie veraenderte Ressourcen (lazy static — const verbietet
# Ressourcen-Konstruktoren).
static var _spark_mesh: BoxMesh = null
static var _ramp_warm: Gradient = null
static var _ramp_cyan: Gradient = null
static var _mat_warm: StandardMaterial3D = null   # warm-weiss/amber
static var _mat_cyan: StandardMaterial3D = null   # kuehles blasses Zyan (Parry)

var _active: Array = []       # [{gen, ps: CPUParticles3D, timer}] aelteste zuerst


static func _shared_mesh() -> BoxMesh:
	if _spark_mesh == null:
		_spark_mesh = BoxMesh.new()
		_spark_mesh.size = Vector3(0.012, 0.04, 0.012)   # schlank, low-poly
	return _spark_mesh


static func _shared_ramp(p1: Color, p2: Color) -> Gradient:
	# Alpha-Fade von voller Deckkraft nach transparent (vertex color ramp).
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([p1, p2])
	return g


static func _warm_ramp() -> Gradient:
	if _ramp_warm == null:
		_ramp_warm = _shared_ramp(
			Color(1.0, 0.85, 0.55, 1.0),   # warm-weiss
			Color(0.95, 0.55, 0.15, 0.0))  # amber ausfransen
	return _ramp_warm


static func _cyan_ramp() -> Gradient:
	if _ramp_cyan == null:
		_ramp_cyan = _shared_ramp(
			Color(0.75, 0.95, 1.0, 1.0),   # blasses Kuehlweiss
			Color(0.25, 0.70, 0.85, 0.0))  # blasses Zyan ausfransen
	return _ramp_cyan


static func _make_material(ramp: Gradient, emission_color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   # selbstleuchtend, keine Lights
	m.albedo_color = Color(1, 1, 1, 1)
	m.emission_enabled = true
	m.emission = emission_color
	m.emission_energy_multiplier = energy
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true   # color_ramp bringt Form UND Alpha
	m.shadow_to_opacity = false
	return m


static func _warm_material() -> StandardMaterial3D:
	if _mat_warm == null:
		_mat_warm = _make_material(_warm_ramp(), Color(1.0, 0.72, 0.30), 1.6)
	return _mat_warm


static func _cyan_material() -> StandardMaterial3D:
	if _mat_cyan == null:
		_mat_cyan = _make_material(_cyan_ramp(), Color(0.55, 0.90, 1.0), 1.4)
	return _mat_cyan


# Startet einen Kontakt-Funkenburst an WELTPOSITION.
# direction: Stoss-/Abprallrichtung (wird normalisiert; (0,0,0) -> (0,1,0)).
# parry=true: kuehleres Zyan + grosser Burst (18 statt 10 Partikel).
func emit_contact(world_position: Vector3, direction: Vector3, parry: bool = false) -> void:
	# Kapazitaet: aeltester Burst retired (inkl. Timer), BEVOR der siebte entsteht.
	while _active.size() >= MAX_BURSTS:
		_retire(_active.pop_front())
	var ps := CPUParticles3D.new()
	ps.name = "Sparks"
	ps.amount = AMOUNT_PARRY if parry else AMOUNT_NORMAL
	ps.lifetime = LIFETIME_SPAN
	ps.one_shot = true
	ps.emitting = false
	ps.explosiveness = 1.0                      # Ein-Burst-Kontakt, kein Dauerstrahl
	ps.preprocess = 0.0
	ps.local_coords = false
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
	ps.mesh = _shared_mesh()
	var dir := direction.normalized() if direction.length_squared() > 1e-9 else FALLBACK_DIR
	ps.direction = dir
	ps.spread = CONE_DEG
	ps.initial_velocity_min = SPEED_MIN
	ps.initial_velocity_max = SPEED_MAX
	ps.gravity = GRAVITY
	ps.angular_velocity_min = 0.0
	ps.angular_velocity_max = 0.0
	ps.angle_min = 0.0
	ps.angle_max = 0.0
	ps.damping_min = 0.0
	ps.damping_max = 0.0
	ps.scale_amount_min = 0.6                   # leicht gestreut, aber klein
	ps.scale_amount_max = 1.15 if parry else 1.0
	ps.color_ramp = _cyan_ramp() if parry else _warm_ramp()
	ps.material_override = _cyan_material() if parry else _warm_material()
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ps.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(ps)
	# top_level NACH dem Adden; globale Basis exakt IDENTITY (H18/H19-Lektion).
	ps.top_level = true
	ps.global_transform = Transform3D(Basis.IDENTITY, world_position)
	ps.emitting = true
	ps.restart()
	var timer := Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = CLEANUP_DELAY
	var entry := {"ps": ps, "timer": timer}
	timer.timeout.connect(_on_timer.bind(entry))
	add_child(timer)
	_active.append(entry)


func clear() -> void:
	while not _active.is_empty():
		_retire(_active.pop_front())


func active_count() -> int:
	return _active.size()


func _on_timer(entry: Dictionary) -> void:
	# Der uns feuernde Timer gibt SICH SELBST frei — auch im Stale-Fall nach
	# clear()/Retire; one_shot wuerde ihn sonst nur stoppen, nie freigeben.
	if _active.has(entry):
		_active.erase(entry)
		if is_instance_valid(entry["ps"]):
			entry["ps"].queue_free()
	if is_instance_valid(entry["timer"]):
		entry["timer"].queue_free()


func _retire(entry: Dictionary) -> void:
	_active.erase(entry)
	if is_instance_valid(entry["ps"]):
		entry["ps"].queue_free()
	if is_instance_valid(entry["timer"]):
		entry["timer"].queue_free()
