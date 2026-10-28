extends Node3D
## H28 — Brecher-Haemesser (industrieller Cleaver), reines Visual-Modul.
## Geometrie wird EINMAL beim ersten _ready() gebaut. Keine Lights, Physik, Timer, Audio,
## Kollision, Datei-IO, Per-Frame-Logik, Owner-Referenzen; kein class_name.
##
## Autoring-Konvention (wie hero_sword/vibroblade, docs/contract-chaser-
## weapon-socket.md): Root identity am Grip-Pivot, Langachse +Y, Griff nach
## unten (Grip-Ende y=-0.100), Spitze y=+0.950, Breite in X, Tiefe in Z — die
## breite Blattseite liegt in der XY-Ebene und ist damit einer +Z-Kamera
## zugewandt. Masse VOR dem bestehenden enemy-Scale 0.58:
##   Laenge 1.050 m (0.95..1.10) | Breite 0.275 m (0.22..0.28) | Tiefe 0.060 m (0.035..0.07).
##
## Silhouette: gedrungene, vorlastige Industrieform — breites Blatt mit
## Ausbauchung zur Spitze, gekappte winklige Spitze (Clip von Rueckenecke
## (0.100,0.860) auf Schneidenecke (-0.070,0.950)), Schneide an der -X-Seite
## mit schmalem hellem Schraeff-Schliff, dunkler Gunmetal-Koerper,
## rueckhaltende Kupfer-Verstarkungsleiste mit zwei Nieten an der Rueckenseite,
## Panzerbuckel ueber dem Blattruecken zur Gewichtsdeutung. Zweckvolle
## Asymmetrie (Schneide-/Rueckenseite verschieden), KEINE Box-Sammlung
## unrelated Formen; alle Details haengen an EINEM Root und sind duplizierbar
## fuer den Abwurf als Rigid Weapon (enemy._drop_weapon dupliziert den Zweig).
##
## Winding (Codex-Regel nach H22-Review): Godot-Frontseite ist IM UHRZEIGERSINN
## von aussen gesehen, nach aussen weisende Normalen, CULL_BACK — kein
## CULL_DISABLED. _add_tri_out wendet das bewaehrte bedingte Swap-Muster an.
##
## Budget: 14 MeshInstance3D, 4 geteilte StandardMaterial3D, 188 Dreiecke
## (13 BoxMesh x 12 = 156 + ArrayMesh-Blatt 32). Materialien opak PBR,
## Stil robuste gebrauchte Metalle; keine Textur-Ressourcen (keine
## Fake-Textur-Behauptungen), kein Emissions-/Cyan-Anteil.

static var _mat_gunmetal: StandardMaterial3D = null
static var _mat_bevel: StandardMaterial3D = null
static var _mat_copper: StandardMaterial3D = null
static var _mat_grip: StandardMaterial3D = null
static var _blade_mesh: ArrayMesh = null


static func _gunmetal_mat() -> StandardMaterial3D:
	if _mat_gunmetal == null:
		_mat_gunmetal = StandardMaterial3D.new()
		_mat_gunmetal.albedo_color = Color(0.30, 0.32, 0.35)  # dunkles Gunmetal
		_mat_gunmetal.metallic = 0.45
		_mat_gunmetal.roughness = 0.65                            # gebraucht, matt geschliffen
		_mat_gunmetal.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_gunmetal


static func _bevel_mat() -> StandardMaterial3D:
	if _mat_bevel == null:
		_mat_bevel = StandardMaterial3D.new()
		_mat_bevel.albedo_color = Color(0.82, 0.84, 0.87)         # heller frischer Schliff
		_mat_bevel.metallic = 0.9
		_mat_bevel.roughness = 0.2
		_mat_bevel.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_bevel


static func _copper_mat() -> StandardMaterial3D:
	if _mat_copper == null:
		_mat_copper = StandardMaterial3D.new()
		_mat_copper.albedo_color = Color(0.45, 0.24, 0.12)        # gedämpftes Kupfer
		_mat_copper.metallic = 0.9
		_mat_copper.roughness = 0.45
		_mat_copper.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_copper


static func _grip_mat() -> StandardMaterial3D:
	if _mat_grip == null:
		_mat_grip = StandardMaterial3D.new()
		_mat_grip.albedo_color = Color(0.06, 0.06, 0.065)         # matte Hartgummi-Wickel
		_mat_grip.metallic = 0.05
		_mat_grip.roughness = 0.92
		_mat_grip.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_grip


func _ready() -> void:
	# Aufbau EINMAL beim ersten Baumeintritt. enemy._drop_weapon dupliziert den
	# Waffen-Zweig via duplicate(); die Kopie bringt ihre 14 Mesh-Kinder schon
	# mit und laeuft beim Anhaegen an das RigidBody erneut durch _ready — mit
	# Kindern ueberspringen wir dann den Aufbau (sonst stapelt sich die Geometrie
	# doppelt). Ein frisches, noch nie im Baum gewesenes Duplikat (0 Kinder)
	# baut korrekt selbst auf. (is_duplicating() ist in Godot 4.7.2 dieses
	# Builds GDScript-seitig nicht verfuegbar — Kinder-Zahl ist der zuverlaessige
	# Indikator.)
	if get_child_count() == 0:
		_build()


func _build() -> void:
	# --- Griffstapel (Grip-Pivot = Ursprung), Ende bei y = -0.100
	_add_box("Grip1", Vector3(0.044, 0.052, 0.046), Vector3(0.0, -0.012, 0.0), _grip_mat())
	_add_box("Grip2", Vector3(0.046, 0.052, 0.050), Vector3(0.0, -0.058, 0.0), _grip_mat())
	_add_box("Pommel", Vector3(0.058, 0.024, 0.058), Vector3(0.0, -0.088, 0.0), _gunmetal_mat())
	# --- massive, asymmetrische Parierstange (x -0.140..+0.120) + Nocken zur Schneidenseite
	_add_box("Guard", Vector3(0.260, 0.060, 0.055), Vector3(-0.010, 0.040, 0.0), _gunmetal_mat())
	_add_box("GuardLug", Vector3(0.050, 0.085, 0.060), Vector3(-0.115, 0.045, 0.0), _gunmetal_mat())
	# --- Klemmhals zum Blatt
	_add_box("Collar", Vector3(0.100, 0.050, 0.048), Vector3(-0.005, 0.075, 0.0), _gunmetal_mat())
	# --- Blatt (ArrayMesh, XY-Profil in Z ±0.020 extrudiert), y 0.075..0.950
	_add_mesh("Blade", _blade_array_mesh(), Vector3.ZERO, _gunmetal_mat())
	# --- schmaler heller Schliff entlang der Schneide (-X), dreifach der Kontur folgend
	_add_box("EdgeLower", Vector3(0.014, 0.300, 0.028), Vector3(-0.117, 0.290, 0.0), _bevel_mat())
	_add_box("EdgeUpper", Vector3(0.014, 0.300, 0.028), Vector3(-0.107, 0.590, 0.0), _bevel_mat())
	_add_box("EdgeTip", Vector3(0.014, 0.170, 0.028), Vector3(-0.086, 0.845, 0.0), _bevel_mat())
	# --- Kupfer-Verstarkungsleiste an der Rueckenseite + zwei Nieten (rueckhaltend)
	_add_box("RibPlate", Vector3(0.014, 0.440, 0.036), Vector3(0.126, 0.560, 0.0), _copper_mat())
	_add_box("Rivet1", Vector3(0.018, 0.016, 0.042), Vector3(0.126, 0.430, 0.0), _copper_mat())
	_add_box("Rivet2", Vector3(0.018, 0.016, 0.042), Vector3(0.126, 0.700, 0.0), _copper_mat())
	# --- Panzerbuckel ueber dem Blattruecken: Vorlast-Industriecharakter
	_add_box("ShoulderMass", Vector3(0.055, 0.140, 0.050), Vector3(0.090, 0.760, 0.0), _gunmetal_mat())


func _add_box(node_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _add_mesh(node_name, bm, pos, mat)


func _add_mesh(node_name: String, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.transform = Transform3D(Basis.IDENTITY, pos)
	mi.material_override = mat
	add_child(mi)
	return mi


# ---------------------------------------------------------------------------
# ArrayMesh-Klinge: gedrungener Cleaver-Grundriss in der XY-Ebene (X Breite,
# Y Laenge), in Z ±0.020 extrudiert (Gesamt 0.040). Profil gegen den
# Uhrzeigersinn von +Z gesehen; _add_tri_out orientiert Normalen nach aussen
# und liefert die Uhrzeigersinn-Windung fuer Godots Frontseite.

## Konturpunkte (x, y): Basis schmal, Breite nimmt zur Spitze zu
## (Vorlast), Spitze winklig gekappt.
const PROFILE: Array[Vector2] = [
	Vector2(-0.100, 0.075),   # Basis Schneidenseite
	Vector2(0.095, 0.075),    # Basis Rueckenseite
	Vector2(0.125, 0.300),    # Ruecken wird breit
	Vector2(0.130, 0.560),    # breitestes Rueckensegment
	Vector2(0.100, 0.860),    # Rueckenecke (Clip-Anfang)
	Vector2(-0.070, 0.950),   # gekappte Spitze (Clip-Ende auf der Schneidenseite)
	Vector2(-0.115, 0.700),   # Schneidenausbauch oben
	Vector2(-0.125, 0.380),   # breitester Schneidepunkt
]
const BLADE_DZ := 0.020


func _blade_array_mesh() -> ArrayMesh:
	if _blade_mesh != null:
		return _blade_mesh
	var centroid := Vector2.ZERO
	for p in PROFILE:
		centroid += p
	centroid /= float(PROFILE.size())
	var inside := Vector3(centroid.x, centroid.y, 0.0)  # garantierter Innenpunkt
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var n := PROFILE.size()
	for i in n:
		var a: Vector2 = PROFILE[i]
		var b: Vector2 = PROFILE[(i + 1) % n]
		# Mantel: zwei Dreiecke pro Segment (Vorderseite Z=+dz, Rueckseite Z=-dz)
		_add_tri_out(verts, normals,
			Vector3(a.x, a.y, BLADE_DZ), Vector3(b.x, b.y, BLADE_DZ),
			Vector3(a.x, a.y, -BLADE_DZ), inside)
		_add_tri_out(verts, normals,
			Vector3(b.x, b.y, BLADE_DZ), Vector3(b.x, b.y, -BLADE_DZ),
			Vector3(a.x, a.y, -BLADE_DZ), inside)
	# Kappen: Faelcher vom Profil-Schwerpunkt (sternfoermiges Volumen)
	for i in n:
		var a: Vector2 = PROFILE[i]
		var b: Vector2 = PROFILE[(i + 1) % n]
		_add_tri_out(verts, normals,
			Vector3(a.x, a.y, BLADE_DZ), Vector3(b.x, b.y, BLADE_DZ),
			Vector3(centroid.x, centroid.y, BLADE_DZ), inside)
		_add_tri_out(verts, normals,
			Vector3(a.x, a.y, -BLADE_DZ), Vector3(b.x, b.y, -BLADE_DZ),
			Vector3(centroid.x, centroid.y, -BLADE_DZ), inside)
	var arr := Array()
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	am.custom_aabb = AABB(Vector3(-0.125, 0.075, -BLADE_DZ), Vector3(0.255, 0.875, 2.0 * BLADE_DZ))
	_blade_mesh = am
	return am


## Godot-Front = Uhrzeigersinn von aussen, Normalen nach aussen, CULL_BACK.
## Bedingter Swap (Muster aus vibroblade_visual.gd/H22): RIGHT-Hand-Normale
## gegen die Aussenrichtung pruefen, ggf. Reihenfolge tauschen, damit die
## emittierte Reihenfolge konsistent CLOCKWISE-Front mit Outward-Normalen ist.
func _add_tri_out(verts: PackedVector3Array, normals: PackedVector3Array, p0: Vector3, p1: Vector3, p2: Vector3, inside: Vector3) -> void:
	var nrm := (p1 - p0).cross(p2 - p0)
	if nrm.length_squared() < 1e-12:
		return
	var tri_center := (p0 + p1 + p2) * (1.0 / 3.0)
	if nrm.dot(tri_center - inside) >= 0.0:
		verts.append(p0)
		verts.append(p2)
		verts.append(p1)
		nrm = nrm.normalized()
	else:
		verts.append(p0)
		verts.append(p1)
		verts.append(p2)
		nrm = (-nrm).normalized()
	normals.append(nrm)
	normals.append(nrm)
	normals.append(nrm)
