extends Node3D
## H47 — slash_trail: dezente, kurze Schwertspur als eigenstaendiges Node3D-Modul.
## Vertrag: Codex-Auftrag H47 (07.10.2026) — Zielres://modules/vfx/slash_trail.gd.
##
## API:
##   sample(base_world, tip_world, delta) — baut die Spur NUR aus expliziten
##     Aufrufen auf (keine automatische Spieler-/Knochen-Suche). Weltpunkte des
##     Klingenanfangs (Griff/Hand) und der Spitze.
##   clear() — entfernt die Spur sofort und setzt die History zurueck.
##
## Vertrag erfuellt:
## - Historie 0.06 s; hoechstens 8 Punkte => hoechstens 7 Segmente.
## - EIN wiederverwendetes MeshInstance3D (ein ImmediateMesh, genau ein Surface);
##   pro sample() wird nur die Surface neu gefuellt — es entstehen KEINE Nodes
##   pro Frame.
## - EIN transparent-unshaded kupferweisses StandardMaterial3D, geteilt und
##   unveraenderlich (lazy static var — GDScript-const verbietet
##   Ressourcen-Konstruktoraufrufe); Schatten aus; CULL_DISABLED, weil die
##   Bahnrichtung beliebig ist und die Spur aus allen Blickwinkeln sichtbar bleiben soll.
## - Alpha blendet zu alten Samples linear auf 0 aus (zeitbasiert, nicht
##   indexbasiert — auch bei unregelmaessigen Aufrufabstaenden korrekt).
## - Historie bleibt in Weltkoordinaten; beim Neuaufbau ueber die aktuelle
##   global_transform.affine_inverse() in lokale
##   Koordinaten umgerechnet; haengt das Modul an einem bewegten Parent, bleibt
##   die Spur korrekt im Weltraum verankert.
## - Keine Lichter, keine Kollision, kein Audio, kein FX/Player/Enemy-Zugriff,
##   keine Dateien, kein class_name, keine Per-Frame-Logik ohne sample()-Aufruf.
##
## Zeitbasis: interner, per sample(delta) vorwaertsgeschalteter Takt — der
## Aufrufer bestimmt die Zeitskala (hitstop-treu, wenn delta das echte Skala-delta ist).

const HISTORY_S := 0.06      # Vertrag: 0.06 s Historie
const MAX_POINTS := 8        # Vertrag: hoechstens 8 Segmente-Paare (7 Segmente)
const BASE_ALPHA := 0.30     # dezenter Peak-Pegel; aelteste Samples -> 0.0

static var _trail_mat: StandardMaterial3D = null

var _mesh_instance: MeshInstance3D
var _imm: ImmediateMesh
var _hist: Array = []        # [{t: float, b: Vector3 (world), p: Vector3 (world)}, ...] aeltester zuerst
var _time := 0.0


static func _material() -> StandardMaterial3D:
	if _trail_mat == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color(1.0, 1.0, 1.0)   # Farb-/Alpha-Multiplikator; Kupferweiss kommt pro Vertex
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 1.0
		m.metallic = 0.0
		_trail_mat = m
	return _trail_mat


func _init() -> void:
	_imm = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TrailMesh"
	_mesh_instance.mesh = _imm
	_mesh_instance.material_override = _material()
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_instance.visible = false   # erst sichtab dem ersten sample()
	add_child(_mesh_instance)


## Fuegt einen Klingenrahmen (Weltkoordinaten von Griff und Spitze) hinzu und
## baut die Spur neu auf. delta = Zeitschritt seit dem letzten sample() in
## Sekunden (wie im Physics-Frame). Verwaorfene/duplizierte Punkte erzeugen
## keine Nodes — nur die ImmediateMesh-Surface wird aktualisiert.
func sample(base_world: Vector3, tip_world: Vector3, delta: float) -> void:
	_time += maxf(delta, 0.0)
	var entry: Dictionary = {"t": _time, "b": base_world, "p": tip_world}
	# Veraltetes vor dem Anfuegen entfernen (Zeitfenster, nicht Anzahl).
	var cutoff := _time - HISTORY_S
	while not _hist.is_empty() and float(_hist[0]["t"]) <= cutoff:
		_hist.pop_front()
	_hist.append(entry)
	# Hartes Segment-Budget: aelteste fallen lassen.
	while _hist.size() > MAX_POINTS:
		_hist.pop_front()
	_rebuild()


## Entfernt die Spur sofort und setzt die History zurueck.
func clear() -> void:
	_hist.clear()
	_time = 0.0
	_mesh_instance.visible = false
	_imm.clear_surfaces()


func is_trailing() -> bool:
	return _mesh_instance.visible


func point_count() -> int:
	return _hist.size()


func _rebuild() -> void:
	_imm.clear_surfaces()
	if _hist.size() < 2:
		# Noch kein Segment: Spur bleibt unsichtbar (kein Flackern bei Einzelpunkten).
		_mesh_instance.visible = false
		return
	_mesh_instance.visible = true
	var inv := global_transform.affine_inverse()
	_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# Surface nur einmal deklarieren und alle Eckpunkte in einem Durchgang
	# schreiben (Farbe setzt den folgenden Vertex — ImmediateMesh-Muster).
	for i in range(_hist.size() - 1):
		var age0: float = _time - float(_hist[i]["t"])
		var age1: float = _time - float(_hist[i + 1]["t"])
		var a0: float = BASE_ALPHA * clampf(1.0 - age0 / HISTORY_S, 0.0, 1.0)
		var a1: float = BASE_ALPHA * clampf(1.0 - age1 / HISTORY_S, 0.0, 1.0)
		var b0: Vector3 = inv * _hist[i]["b"]
		var p0: Vector3 = inv * _hist[i]["p"]
		var b1: Vector3 = inv * _hist[i + 1]["b"]
		var p1: Vector3 = inv * _hist[i + 1]["p"]
		# Vier Eckpunkte eines Bandes: Griffkante alt->neu, Spitze neu->alt.
		var c_old := _copper(a0)
		var c_new := _copper(a1)
		_imm.surface_set_color(_copper(0.0))
		_imm.surface_add_vertex(b0)
		_imm.surface_set_color(_copper(0.0))
		_imm.surface_add_vertex(b1)
		_imm.surface_set_color(c_new)
		_imm.surface_add_vertex(p1)
		_imm.surface_set_color(c_new)
		_imm.surface_add_vertex(p1)
		_imm.surface_set_color(c_old)
		_imm.surface_add_vertex(p0)
		_imm.surface_set_color(_copper(0.0))
		_imm.surface_add_vertex(b0)
	_imm.surface_end()


static func _copper(alpha: float) -> Color:
	# Kupferweiss (warmes helles Kupfer wie die H44-Cue-Akzentfarbe), Alpha zeitgeblendet.
	return Color(0.93, 0.76, 0.55, alpha)
