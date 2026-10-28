extends Node3D
# H19 — Kleiner beidseitiger Landestaub-Faecher (Ziel: res://modules/vfx/landing_dust.gd).
# Vertrag: outputs/worker_contracts/H19-landing-dust.txt (Codex, 06.10.2026).
# - Standalone Node3D ohne class_name; pro Landung ZWEI gegenlaeufige, flache
#   laterale One-Shot-Faecher (CPUParticles3D links/rechts).
# - Schwelle: |impact_speed| < 4 ueberspringt komplett.
#   strength = clamp((|speed| - 4) / 10, 0, 1).
# - EXPLIZITE winzige Low-Poly-SphereMesh (r=0.015) + mattgraues Material,
#   Schatten aus; one_shot; local_coords false; GLOBALE BASIS IDENTITY
#   (Richtung traegt p.direction); Weltposition = Vorgabe, auch unter
#   rotiert/skaliertem Parent (top_level).
# - directions (-1,0.2,0)/(1,0.2,0); spread 15°; velocity 1..2.5 * (0.5+strength);
#   gravity (0,-6,0); lifetime 0.2..0.35s; amount 6..10 pro Facher (mit strength);
#   Zufallsscale 0.4..1; Fade ueber color_ramp (Alpha 1->0), kein opaker Dauerqualm.
# - Max 4 Landungen / 8 Emitters: vor der fuenften wird die aelteste Landung
#   inklusive IHRES Timers retired. Timer werden bei Timeout UND clear/Retire
#   ausdrucklich freigegeben (H18-Review-Lektion: one_shot stoppt nur, free notabendig).
# - Vollstaendiges Cleanup spaetestens 0.6s; clear() = sofort active_count 0 +
#   queue_free; stale Timer ungefaehrlich (Identitaets-/Token-Check).
# - Kein player-/FX-/Scene-Zugriff, keine Kollision/Schaeden, keine Dateien/Audio.

const MAX_LANDINGS := 4            # 4 Landungen x 2 Facher = 8 Emitters
const CLEANUP_DELAY := 0.55        # s; Vertrag: vollstaendiges Cleanup <= 0.6s
const SPEED_THRESHOLD := 4.0
const SPREAD_DEG := 15.0
const GRAVITY := Vector3(0.0, -6.0, 0.0)
const LIFETIME_MIN := 0.2
const LIFETIME_MAX := 0.35
const DIR_LEFT := Vector3(-1.0, 0.2, 0.0)
const DIR_RIGHT := Vector3(1.0, 0.2, 0.0)
# Geteilt und intern nie veraendert (lazy static — GDScript-const verbietet
# Ressourcen-Konstruktoren). Farbverlauf: mattgrau undurchsichtig -> transparent.
static var _dust_mesh: SphereMesh = null
static var _dust_material: StandardMaterial3D = null
# CPUParticles3D.color_ramp ist in Godot 4 eine Gradient-Resource.
static var _dust_ramp: Gradient = null

static func _shared_mesh() -> SphereMesh:
	if _dust_mesh == null:
		_dust_mesh = SphereMesh.new()
		_dust_mesh.radius = 0.015
		_dust_mesh.height = 0.03
		_dust_mesh.radial_segments = 4  # bewusst Low-Poly (Winzling)
		_dust_mesh.rings = 2
	return _dust_mesh

static func _shared_ramp() -> Gradient:
	if _dust_ramp == null:
		_dust_ramp = Gradient.new()
		_dust_ramp.offsets = PackedFloat32Array([0.0, 1.0])
		_dust_ramp.colors = PackedColorArray([
			Color(0.62, 0.60, 0.55, 1.0),   # mattes Staubgrau
			Color(0.62, 0.60, 0.55, 0.0),   # ausfransen statt opaker Wolke
		])
	return _dust_ramp

static func _shared_material() -> StandardMaterial3D:
	if _dust_material == null:
		_dust_material = StandardMaterial3D.new()
		_dust_material.albedo_color = Color(0.62, 0.60, 0.55)
		_dust_material.roughness = 1.0
		_dust_material.metallic = 0.0
		# Alpha aus der color_ramp (Partikel-Vertex-Farbe) muss durchkommen.
		_dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_dust_material.vertex_color_use_as_albedo = true
		_dust_material.shadow_to_opacity = false
	return _dust_material

var _active: Array = []  # [{gen, fans: Array[CPUParticles3D], timer}, ...] aelteste zuerst
var _generation: int = 0

# Startet einen Landestaub (zwei Facher) an WELTPOSITION.
# |impact_speed| < 4 ist still (kein Staub, kein Knoten).
func emit_landing(world_position: Vector3, impact_speed: float) -> void:
	var speed := absf(impact_speed)
	if speed < SPEED_THRESHOLD:
		return
	var s := clampf((speed - SPEED_THRESHOLD) / 10.0, 0.0, 1.0)
	# Kapazitaet: aelteste Landung retiring, BEVOR die fuenfte erzeugt wird.
	while _active.size() >= MAX_LANDINGS:
		_retire_entry(_active.pop_front(), true)

	var fans: Array = []
	for dirv in [DIR_LEFT, DIR_RIGHT]:
		fans.append(_make_fan(world_position, dirv, s))

	_generation += 1
	var timer := Timer.new()
	timer.wait_time = CLEANUP_DELAY
	timer.one_shot = true
	timer.autostart = true
	var entry := {"gen": _generation, "fans": fans, "timer": timer}
	timer.timeout.connect(_on_timer.bind(entry))
	add_child(timer)
	_active.append(entry)

func clear() -> void:
	while not _active.is_empty():
		_retire_entry(_active.pop_front(), true)

# Zahl aktiver LANDUNGEN (0..MAX_LANDINGS); je Landung gibt es 2 Emitter-Kinder.
func active_count() -> int:
	return _active.size()

func _make_fan(world_position: Vector3, dirv: Vector3, strength: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "DustFan"
	p.one_shot = true
	p.emitting = false
	p.amount = int(round(lerpf(6.0, 10.0, strength)))
	p.lifetime = randf_range(LIFETIME_MIN, LIFETIME_MAX)  # Spielwert pro Facher
	p.lifetime_randomness = 0.0
	p.preprocess = 0.0
	p.explosiveness = 1.0
	p.local_coords = false
	p.mesh = _shared_mesh()          # EXPLIZITES Mesh — sichtbare Staubkoerner
	p.material_override = _shared_material()
	p.color_ramp = _shared_ramp()    # Fade zu transparent (kein Dauerqualm)
	p.visible = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
	p.direction = dirv.normalized()  # Welt-Richtung bei IDENTITY-Basis (H18-Review)
	p.spread = SPREAD_DEG
	p.gravity = GRAVITY
	var vs := 0.5 + strength         # velocity 1..2.5 * (0.5 + strength)
	p.initial_velocity_min = 1.0 * vs
	p.initial_velocity_max = 2.5 * vs
	p.angular_velocity_min = 0.0
	p.angular_velocity_max = 0.0
	p.angle_min = 0.0
	p.angle_max = 0.0
	p.scale_amount_min = 0.4         # Zufallsscale 0.4..1
	p.scale_amount_max = 1.0
	p.damping_min = 0.0
	p.damping_max = 0.0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

	add_child(p)
	# top_level NACH dem Adden; globale Basis bleibt exakt IDENTITY, Position =
	# Weltvorgabe (Review-Korrekturen aus H18 uebernommen).
	p.top_level = true
	p.global_transform = Transform3D(Basis.IDENTITY, world_position)
	p.emitting = true
	p.restart()
	return p

func _on_timer(entry: Dictionary) -> void:
	# Der uns feuernde Timer gibt SICH SELBST frei — auch im Stale-Fall nach
	# clear()/Retire; one_shot wuerde ihn sonst nur stoppen, nie freigeben.
	_free_timer(entry)
	for i in _active.size():
		if _active[i] == entry:
			_retire_entry(_active.pop_at(i), false)
			return

# entry aus der Liste entfernen und Kinder freigeben.
# with_timer=false, wenn der Timer sich bereits selbst befreit hat.
func _retire_entry(entry: Dictionary, with_timer: bool) -> void:
	if with_timer:
		_free_timer(entry)
	var fans: Array = entry["fans"]
	for f in fans:
		if is_instance_valid(f):
			f.emitting = false
			f.queue_free()

func _free_timer(entry: Dictionary) -> void:
	var t = entry.get("timer")
	if t != null and is_instance_valid(t):
		t.queue_free()
