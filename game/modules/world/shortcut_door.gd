extends Node3D
# H16 — Einweg-Abkuerzungstuer (Standalone, Ziel: res://modules/world/shortcut_door.gd).
# Vertrag: outputs/worker_contracts/H16-shortcut.txt (Codex, 06.10.2026).
# - Standalone Node3D; Kind StaticBody3D layer 1 / mask 4.
# - Ursprung = unten mitte; Tuerebene YZ: 0.25m X (Dicke), 2.8m Y (Hoehe), 2m Z (Breite).
# - Stahltafel + Kupferrahmen, teal Riegel zum Standard-Filmkamera-Blick (+Z) lesbar.
# - Fussboden Y=0 (Root fix, nur die Tafel bewegt sich).
# - Offen: Tafel faehrt 3m hoch ueber 0.35s; Kollision sofort (deferred) deaktiviert.
# - Eigene Ressourcen pro Instanz. Kein class_name, kein Save/Input/FX/Gruppen-Zugriff.

signal opened(door_id: String)

const DOOR_THICKNESS := 0.25   # X
const DOOR_HEIGHT := 2.8       # Y
const DOOR_WIDTH := 2.0        # Z
const TRAVEL := 3.0            # Hub der Tafel nach oben (m)
const OPEN_TIME := 0.35        # Sekunden fuer vollen Hub
const SIDE_TOLERANCE := 0.3    # Mindestabstand jenseits der Tuerebene (|X|)
const BOUND_X := 1.6           # maximale Nahzone in X (betretende Seite)
const BOUND_Y := 1.0           # Höhe ueber Boden
const BOUND_Z := 0.8           # Breite entlang der Tuerebene

@export var open_travel: float = TRAVEL
@export var open_time: float = OPEN_TIME
@export var door_id: String = "shortcut"
@export var unlock_from_positive_x: bool = true
# Mission routes can allow either approach; standalone shortcut default stays one-way.
@export var unlock_from_either_side: bool = false

var _open: bool = false
var _opened_emitted: bool = false
var _built: bool = false
var _body: StaticBody3D
var _panel: Node3D
var _tween: Tween

func _init() -> void:
	# Build in _init (nicht _ready): try_open/restore_open/get_body funktionieren
	# damit auch vor Tree-Eintritt (Save-Restore vor Ready gem. Vertrag).
	_ensure_built()

# Baut Geometrie+Ressourcen lazy: restore_open() muss auch VOR Ready funktionieren.
func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_panel = Node3D.new()
	_panel.name = "Panel"
	add_child(_panel)

	_body = StaticBody3D.new()
	_body.name = "DoorBody"
	_body.collision_layer = 1
	_body.collision_mask = 4
	_panel.add_child(_body)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(DOOR_THICKNESS, DOOR_HEIGHT, DOOR_WIDTH)
	shape.shape = box
	# BoxMitte auf halber Höhe -> Fuss der Tafel bei Y=0 (Root = unten mitte).
	shape.position = Vector3(0.0, DOOR_HEIGHT * 0.5, 0.0)
	_body.add_child(shape)

	# Alle Ressourcen pro Instanz neu erzeugt (keine geteilten Materials/Meshes).
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.45, 0.47, 0.50)
	steel.metallic = 0.9
	steel.roughness = 0.35

	var panel_mesh := MeshInstance3D.new()
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(DOOR_THICKNESS, DOOR_HEIGHT, DOOR_WIDTH)
	panel_mesh.mesh = panel_box
	panel_mesh.material_override = steel
	panel_mesh.position = Vector3(0.0, DOOR_HEIGHT * 0.5, 0.0)
	_panel.add_child(panel_mesh)

	var copper := StandardMaterial3D.new()
	copper.albedo_color = Color(0.72, 0.45, 0.20)
	copper.metallic = 1.0
	copper.roughness = 0.3

	var frame := MeshInstance3D.new()
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(DOOR_THICKNESS * 0.6, DOOR_HEIGHT + 0.2, DOOR_WIDTH + 0.2)
	frame.mesh = frame_box
	frame.material_override = copper
	frame.position = Vector3(0.0, DOOR_HEIGHT * 0.5, 0.0)
	_panel.add_child(frame)

	var latch := MeshInstance3D.new()
	var latch_box := BoxMesh.new()
	latch_box.size = Vector3(0.10, 0.30, 0.50)
	latch.mesh = latch_box
	var teal := StandardMaterial3D.new()
	teal.albedo_color = Color(0.0, 0.80, 0.75)
	teal.emission_enabled = true
	teal.emission = Color(0.0, 0.80, 0.75)
	teal.emission_energy_multiplier = 1.5
	latch.material_override = teal
	# Riegel kameraseitig +Z (z nahe 1.0, Codex-Korrektur 06.10.): Tab am +Z-Ende,
	# von einer Kamera die in -Z blickt, direkt einsehbar — nicht in der Tuermitte z=0.
	latch.position = Vector3(0.0, 1.2, 0.95)
	_panel.add_child(latch)

	if _open:
		_apply_pose(true)

# Versucht die Tuer zu oeffnen. false ohne jede Zustaends-Aenderung.
# Schwellen mit kleinstem Toleranz-Puffer (EPS): Vector3 speichert float32,
# Literal 1.6 wird zu 1.6000000238 — inklusive Grenzen bleiben sonst falsch herum.
const EPS := 0.0001

func try_open(actor_position: Vector3) -> bool:
	_ensure_built()
	var local := to_local(actor_position)
	var side_ok := (local.x >= SIDE_TOLERANCE - EPS) if unlock_from_positive_x \
		else (local.x <= -(SIDE_TOLERANCE - EPS))
	if unlock_from_either_side:side_ok = absf(local.x) >= SIDE_TOLERANCE - EPS
	var reach_ok := absf(local.x) <= BOUND_X + EPS \
		and absf(local.y) <= BOUND_Y + EPS \
		and absf(local.z) <= BOUND_Z + EPS
	if not (side_ok and reach_ok):
		return false
	if _open:
		return true  # wiederholt, solange offen — kein Ereignis
	_open = true
	if is_inside_tree():
		_start_open_tween()
	else:
		_apply_pose(true)  # ohne Tree kein Tween moeglich — Pose sofort
	# Kollision SOFORT deaktivieren — aufrufender Frame soll nicht mehr blockieren,
	# aber erst nachdem der aktuelle Physik-Frame die Shapes gelesen hat.
	if is_inside_tree():
		call_deferred("_sync_collision")
	else:
		_body.collision_layer = 0
	if not _opened_emitted:
		_opened_emitted = true
		opened.emit(door_id)
	return true

# Setzt Zustand/Pose sofort, OHNE opened-Ereignis. true = offen (kein Tween),
# false = geschlossen und ein frischer oeffnungsberechtiger Versuch ist moeglich.
func restore_open(value: bool) -> void:
	_ensure_built()
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null
	_open = value
	if value:
		_opened_emitted = true  # wiederhergestellt gilt als bereits eroeffnet
	else:
		_opened_emitted = false  # frische Oeffnung nach Reset darf wieder melden
	_apply_pose(value)
	# Kollisionszustand deckungsgleich mit der Pose halten.
	_body.collision_layer = 0 if value else 1

func is_open() -> bool:
	return _open

# --- Lesbare Nachlesen fuer Tests/Integration (keine Seiteneffekte) -----------

func panel_offset_y() -> float:
	return 0.0 if _panel == null else _panel.position.y

func get_body() -> Node:
	return _body

func get_panel() -> Node:
	return _panel

func _apply_pose(open_pose: bool) -> void:
	_panel.position.y = open_travel if open_pose else 0.0

func _start_open_tween() -> void:
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.tween_property(_panel, "position:y", open_travel, open_time)

func _sync_collision() -> void:
	_body.collision_layer=0 if _open else 1
