extends Node3D
# H17 — Gesweeptes Energieprojektil (Standalone, Ziel: res://modules/combat/energy_bolt.gd).
# Vertrag: outputs/worker_contracts/H17-projectile.txt (Codex, 06.10.2026).
# - Node3D ohne class_name; deterministische, begrenzte Lebensdauer.
# - pro Physik-Frame Sweep-Ray von aktueller Position nach naechster:
#   PhysicsRayQueryParameters3D, collide_with_bodies=true, areas=false —
#   faengt duenne Waende auch bei hoher Geschwindigkeit (kein Tunneln).
# - Erster Treffer: Position zum Touchpoint, resolved VOR Signal markiert,
#   Processing aus + Visual aus, impacted genau einmal. Root bleibt am Leben —
#   der Caller deutet den Treffer und freed das Node (kein free() hier).
# - Verfall: stop/versteckt OHNE Hit-Ereignis. Nullgeschwindigkeit harmlos.
# - launch() setzt Position/Geschwindigkeit/Timer/resolved zurueck und erlaubt
#   Reuse; vor und nach Ready. Weltkoordinaten auch bei transformiertem Parent.
# - Kein Schaden/Player-/Enemy-/Gruppen-/Save-/Input-/Audio-Zugriff. Kein Homing,
#   keine Explosion, keine Reflexion. Eigene Ressourcen pro Instanz.

signal impacted(collider: Object, point: Vector3, normal: Vector3)

@export var lifetime: float = 3.0

var _pending_origin: Variant = null

func _ready() -> void:
	if _pending_origin != null:
		global_position = _pending_origin
		_pending_origin = null

var _velocity: Vector3 = Vector3.ZERO
var _mask: int = 0
var _exclude: Array[RID] = []
var _time_left: float = 0.0
var _resolved: bool = true  # vor dem ersten Start gilt: nicht unterwegs
var _visual: MeshInstance3D

func _init() -> void:
	# Bau in _init (wie H16): launch() darf vor Tree-Eintritt alles setzen.
	_visual = MeshInstance3D.new()
	_visual.name = "BoltVisual"
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	_visual.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.9, 1.0)
	mat.emission_energy_multiplier = 2.5
	_visual.material_override = mat
	_visual.visible = false  # unsichtbar bis launch (MeshInstance3D wäre sonst sichtbar)
	add_child(_visual)

# Startet (oder startet neu) den Flug. origin/velocity sind WELTKoordinaten.
func launch(origin: Vector3, velocity: Vector3, mask: int, exclude: Array[RID] = []) -> void:
	if is_inside_tree():
		_pending_origin = null
		global_position = origin
	else:
		_pending_origin = origin
		position = origin  # ohne Baum ist global == lokal (kein Transform-Zugriff)
	_velocity = velocity
	_mask = mask
	_exclude.clear()
	for rid in exclude:
		_exclude.append(rid)
	_time_left = maxf(lifetime, 0.0)
	_resolved = false
	_visual.visible = true
	set_physics_process(true)

func is_resolved() -> bool:
	return _resolved

func _physics_process(delta: float) -> void:
	if _resolved:
		return
	if _time_left <= 0.0:
		_finish();return
	var step := minf(maxf(delta,0.0),_time_left)
	var from := global_position
	var to := from + _velocity * step
	# Sweep statt Punkt: Segment von jetzt nach naechster Frame-Position.
	var params := PhysicsRayQueryParameters3D.create(from, to, _mask, _exclude)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(params)
	if not hit.is_empty():
		global_position = hit["position"]
		_finish()  # resolved + Processing aus + Visual aus — VOR dem Signal
		impacted.emit(hit["collider"], hit["position"], hit["normal"])
		return
	global_position = to
	_time_left -= step
	if _time_left <= 0.0:
		_finish()  # Verfall ohne Hit-Ereignis

func _finish() -> void:
	_resolved = true
	set_physics_process(false)
	_visual.visible = false
