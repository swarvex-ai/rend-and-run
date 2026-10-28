extends Node3D
## H53 — coolant_release_visual.gd
## Stehender, kurzlebiges Druckwellen-Visual (0.4 s) fuer die Kuehlmittelfreiset-
## zung nach dem Kanister-Bruch (H52). NUR VISUAL: keine Gameplay-Logik, keine
## Physik, kein Schaden, keine Spieler-/Gegner-Referenzen, kein Audio, keine
## Texturen, keine Datei-IO, keine Szenensuche, keine Lichter.
## API: emit_release(origin: Vector3) startet die Welle am Uebergebenen
## WELTPUNKT, clear() versteckt sofort und setzt zurueck, is_active() zeigt den
## Zustand. Genau EINE wiederverwendete MeshInstance3D mit generiertem
## Ring-ArrayMesh in der XY-Ebene (+Z-Kamera), 24 Segmente.
## Ablauf: Radius 0.15 -> 2.2 m, Dicke 0.035 m, Alpha 0.28 -> 0 in 0.4 s;
## endet automatisch unsichtbar. KEIN opakes Zentrum, kein Blitz — duenner,
## kurzer Ripple, der die Silhouette nicht zudeckt.
## Parent-Drift-Schutz: Weltursprung wird gespeichert und ueber
## global_position gesetzt; erneutes emit_restartet denselben Ring statt
## eine zweite Instanz anzulegen. Inaktiv ist die Verarbeitung abgeschaltet.

const DURATION_S := 0.4
const R_START := 0.15
const R_END := 2.2
const THICKNESS := 0.035
const SEGMENTS := 24
const ALPHA_START := 0.28

var _ring: MeshInstance3D
var _mesh: ArrayMesh
var _mat: StandardMaterial3D
var _t := 0.0
var _active := false

func _init() -> void:
	top_level = true # Preserve world XY basis and origin while parent moves.
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(0.55, 0.95, 1.0, 0.0)   # fahles Cyan, Alpha pro Frame
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = false
	_mat.emission_enabled = false

	_mesh = ArrayMesh.new()
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	_ring.mesh = _mesh
	_ring.material_override = _mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_ring.visible = false
	add_child(_ring)
	set_process(false)

func emit_release(origin: Vector3) -> void:
	# Nicht-endliche Werte sicher ablehnen (kein Absturz, kein Zustand).
	if not (is_finite(origin.x) and is_finite(origin.y) and is_finite(origin.z)):
		return
	# Weltursprung speichern und global setzen: ein verschobener/gedrehter
	# Parent kann die Welle nicht zu einem alten Ort ziehen.
	global_position = origin
	_t = 0.0
	_active = true
	_ring.visible = true
	_update_ring()
	set_process(true)

func clear() -> void:
	_active = false
	_t = 0.0
	_ring.visible = false
	set_process(false)

func is_active() -> bool:
	return _active

func ring_instance() -> MeshInstance3D:
	# Diagnose fuer Smoke-Test/Lead: zeigt, dass es genau EIN Ring ist.
	return _ring

func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	if _t >= DURATION_S:
		clear()                 # Ende: automatisch unsichtbar, Verarbeitung aus
		return
	_update_ring()

func _update_ring() -> void:
	var k := clampf(_t / DURATION_S, 0.0, 1.0)
	var outer := lerpf(R_START, R_END, k)
	var inner := maxf(outer - THICKNESS, 0.0005)
	# Ring in der XY-Ebene (Normal +Z zeigt zur +Z-Seitenkamera).
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for i in SEGMENTS + 1:
		var a := TAU * float(i) / float(SEGMENTS)
		var c := cos(a)
		var s := sin(a)
		verts.push_back(Vector3(c * outer, s * outer, 0.0))
		normals.push_back(Vector3(0, 0, 1))
		uvs.push_back(Vector2(float(i) / float(SEGMENTS), 0.0))
		verts.push_back(Vector3(c * inner, s * inner, 0.0))
		normals.push_back(Vector3(0, 0, 1))
		uvs.push_back(Vector2(float(i) / float(SEGMENTS), 1.0))
	var idx := PackedInt32Array()
	for i in SEGMENTS:
		var v0 := i * 2
		idx.push_back(v0)
		idx.push_back(v0 + 1)
		idx.push_back(v0 + 2)
		idx.push_back(v0 + 1)
		idx.push_back(v0 + 3)
		idx.push_back(v0 + 2)
	var arrays := Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	# Dasselbe Mesh-Objekt wird aktualisiert — kein neuer Knoten, keine neue
	# Ressource pro Frame (Godot 4 kennt kein surface_update_arrays; deshalb
	# Flaeche zuruecksetzen und mit den neuen Arrays fuellen).
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var col := _mat.albedo_color
	col.a = ALPHA_START * (1.0 - k)
	_mat.albedo_color = col
