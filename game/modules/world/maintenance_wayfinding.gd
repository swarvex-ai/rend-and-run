extends Node3D
## H34 — Wartungssteg-Wegweisung (eigenstaendiges wiederverwendbares Marker-Modul).
##
## Zweck: Spieler sieht den oberen Wartungssteg, BEVOR er die verriegelte
## Westtuer bei x=16.5 erreicht. Ein Marker-Ursprung sitzt am Befestigungspunkt
## (Wand/Pfeiler); Codex waehlt die finalen Positionen. Das Modul bewegt weder
## Kamera noch Route und hat keine Physik, keine Lights, keine Texturen, keine
## Per-Frame-Logik und kein Blinken.
##
## Lesbarkeit: bestehende Seitenkamera folgt mit offset (0, 1.05, 5.8) und
## blickt von +Z nach -Z (lab_route.gd / main.gd Konvention). Alle Flaechen
## zeigen nach +Z; das Label3D nutzt die lab_route-Konvention
## (font_size 40, pixel_size 0.0055, modulate) auf der kamera-zugewandten Seite.
##
## Oeffentliche API (funktioniert VOR und NACH _ready — Aufbau in _init wie
## beim shortcut_door-Muster H16; Konfiguration wird bewahrt):
##   configure(direction: Vector2, label: String)
##       direction im Bildschirmraum (x=+1 rechts, y=+1 hoch); wird auf 8
##       Himmelsrichtungen gerastert (industriell saubere Pfeile).
##       (1,1) = hoch-rechts (West-Anflug), (1,0) = rechts (Ost-Landung).
##       label: Schildtext, Default "WARTUNGSSTEG".
##   set_route_open(open: bool)
##       false = bernsteinfarbene Umleitung (Default),
##       true  = gedaempftes Cyan "freigegeben".
##   get_direction() / get_label() / is_route_open()
##
## Budgets (vertragsgemaess): 8 Mesh-Oberflaechen (max 20), genau 1 Label3D,
## Geometrie 1.10 m breit (< 1.2 m), 2 Materialien pro Instanz wiederverwendet,
## kein _process/_physics_process, kein Blinken.

const AMBER := Color(0.86, 0.58, 0.18)        # Umleitung (bernstein)
const CYAN_DIM := Color(0.42, 0.68, 0.70)     # freigegeben (gedaempftes Cyan)
const PLATE_COLOR := Color(0.09, 0.11, 0.14)  # dunkle Traegerplatte

var _label_text := "WARTUNGSSTEG"
var _direction := Vector2(1, 1)
var _route_open := false
var _built := false

var _arrow_group: Node3D
var _sign_label: Label3D
var _mat_paint: StandardMaterial3D
var _mat_plate: StandardMaterial3D


func _init() -> void:
	# Aufbau in _init: configure/set_route_open wirken vor Tree-Eintritt.
	_ensure_built()
	_apply_paint()
	_apply_direction()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	name = "MaintenanceWayfinding"

	# Zwei wiederverwendete Materialien pro Instanz.
	_mat_paint = StandardMaterial3D.new()
	_mat_paint.roughness = 0.55
	_mat_paint.metallic = 0.1
	_mat_paint.emission_enabled = true     # Leuchtfarbe ohne eigene Light
	_mat_plate = StandardMaterial3D.new()
	_mat_plate.albedo_color = PLATE_COLOR
	_mat_plate.roughness = 0.7

	# Traegerplatte 1.10 x 0.62 m, 4 schmale Randprofile (5 Oberflaechen).
	_box("Plate", Vector3(0, 0, 0.02), Vector3(1.10, 0.62, 0.04), _mat_plate)
	_box("FrameTop", Vector3(0, 0.27, 0.045), Vector3(1.10, 0.05, 0.03), _mat_plate)
	_box("FrameBottom", Vector3(0, -0.27, 0.045), Vector3(1.10, 0.05, 0.03), _mat_plate)
	_box("FrameLeft", Vector3(-0.525, 0, 0.045), Vector3(0.05, 0.59, 0.03), _mat_plate)
	_box("FrameRight", Vector3(0.525, 0, 0.045), Vector3(0.05, 0.59, 0.03), _mat_plate)

	# Pfeil oberhalb des kompakten Texts; Lead-Korrektur nach Seitenkamera-Review:
	# Schaft + Spitze + Chevron = 3 weitere Oberflaechen. Die Gruppe traegt
	# die Drehung um ihre eigene Z-Achse; der Gruppen-Ursprung ist der Anker.
	_arrow_group = Node3D.new()
	_arrow_group.name = "ArrowGroup"
	_arrow_group.position = Vector3(0, 0.10, 0.065)
	add_child(_arrow_group)
	_box_in(_arrow_group, "ArrowShaft", Vector3(0.02, 0, 0), Vector3(0.28, 0.09, 0.02), _mat_paint)
	_triangle_in(_arrow_group, "ArrowHead", Vector3(0.22, 0, 0), 0.19)
	_triangle_in(_arrow_group, "Chevron", Vector3(-0.15, 0, 0), 0.12)

	# Text auf kamera-zugewandter Seite (+Z), waagrecht, 1 Label3D gesamt.
	_sign_label = Label3D.new()
	_sign_label.name = "SignLabel"
	_sign_label.text = _label_text
	_sign_label.font_size = 28
	_sign_label.pixel_size = 0.004          # lab_route._sign Konvention
	_sign_label.outline_size = 4
	_sign_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED  # haengt fest an der Wand
	_sign_label.position = Vector3(0, -0.19, 0.07)
	add_child(_sign_label)


## direction im Bildschirmraum (x rechts, y hoch); auf 8 Richtungen gerastert.
func configure(direction: Vector2, label: String) -> void:
	if label != "":
		_label_text = label
	_sign_label.text = _label_text
	_direction = _snap_direction(direction)
	_apply_direction()


func set_route_open(open: bool) -> void:
	_route_open = open
	_apply_paint()


func get_direction() -> Vector2:
	return _direction


func get_label() -> String:
	return _label_text


func is_route_open() -> bool:
	return _route_open


# ---------------------------------------------------------------------------
func _snap_direction(d: Vector2) -> Vector2:
	if d.length_squared() < 0.0001:
		return Vector2(1, 0)
	# 0 Grad = rechts; Godot-Z-Rotation gegen den Uhrzeigersinn, y zeigt rauf.
	var a := rad_to_deg(atan2(d.y, d.x))
	var snapped: float = round(a / 45.0) * 45.0
	return Vector2(cos(deg_to_rad(snapped)), sin(deg_to_rad(snapped)))


func _apply_direction() -> void:
	_arrow_group.rotation.z = atan2(_direction.y, _direction.x)


func _apply_paint() -> void:
	# Bernstein = Umleitung; gedaempftes Cyan = Weg frei. Kein Blinken.
	var paint := CYAN_DIM if _route_open else AMBER
	_mat_paint.albedo_color = paint
	_mat_paint.emission = paint
	_mat_paint.emission_energy_multiplier = 0.35 if _route_open else 0.55
	_sign_label.modulate = Color(0.85, 0.95, 0.95) if _route_open else Color(0.98, 0.96, 0.90)


func _box(node_name: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	return _box_in(self, node_name, pos, size, mat)


func _box_in(parent: Node, node_name: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _triangle_in(parent: Node, node_name: String, pos: Vector3, radius: float) -> MeshInstance3D:
	# Clockwise winding faces the +Z camera; tip points along local +X.
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector3(radius, 0, 0.005), Vector3(-radius * 0.6, -radius * 0.6, 0), Vector3(-radius * 0.6, radius * 0.6, 0)]:
		im.surface_add_vertex(v)
	im.surface_end()
	mi.mesh = im
	mi.material_override = _mat_paint
	mi.position = pos
	parent.add_child(mi)
	return mi
