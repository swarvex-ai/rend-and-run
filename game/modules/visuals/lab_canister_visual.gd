extends Node3D
## H52 — lab_canister_visual.gd
## Originaler Zerstoerbarer Labor-Kuehlkanister — NUR VISUAL.
## Zwei Zustaende (intakt/zerbrochen) werden EINMAL in _ready() angelegt;
## set_broken(bool) schaltet nur die Sichtbarkeit der beiden Gruppen — keine
## Nodes/Materialien wachsen beim Umschalten. reset_visual() = zurueck zu
## intakt. Keine Kollision, kein Gameplay, kein Audio, keine Timer, keine
## Prozesslogik (kein _process/_physics_process), keine Datei-IO, keine
## Partikel/Explosion. Trefferbehandlung/Belohnung besitzt der Lead.
## Vertrag: Fuesse am Ursprung, Y oben, betrachtet von +Z.
## Grenzen BEIDER Zustaende: X/Z [-0.35, 0.35], Y [0, 1.0].
## Intakte Silhouette: gedrungener Industriezylinder mit festem Fuss,
## Kupfer-Kragen, Schulter, Top-Ventil, seitlichem Griff und einem schmalen
## cyanen Fuellstand-Fenster auf der Kamera zugewandten +Z-Seite.
## Dunkler matter Stahl; kein Text, kein Licht, keine Transparenz, keine
## Texturen. Zerbrochene Silhouette: kurzer gezackter Rumpf am Boden mit
## abgeschnittenem Kragen-Rest und Bodenfragmenten — Ventil/Top versteckt,
## deutlich kuerzer und kantiger als intakt.
## Budget: 17 MeshInstance3D gesamt (max 18), 3 geteilte Materialien (max 4),
## ~520 Dreiecke (max 1200, exakter Wert steht im Testlog).

const RADIANT := 14   # CylinderMesh-Segmente (bewusst niedrig: Budget + Lab-Look)

@export var steel_color := Color(0.16, 0.18, 0.21)
@export var copper_color := Color(0.69, 0.42, 0.21)
@export var cyan_color := Color(0.25, 0.85, 0.92)

var _mat_steel: StandardMaterial3D
var _mat_copper: StandardMaterial3D
var _mat_cyan: StandardMaterial3D

var _intact: Node3D
var _broken: Node3D

func _ready() -> void:
	_mat_steel = _make_mat(steel_color, 0.75, 0.60)   # dunkler matter Stahl
	_mat_copper = _make_mat(copper_color, 0.80, 0.35)
	_mat_cyan = _make_mat(cyan_color, 0.10, 0.50)     # Fenster: matt, deckend
	_build_intact()
	_build_broken()
	_broken.visible = false

func _make_mat(c: Color, metallic: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = rough
	m.emission_enabled = false
	m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m

func _cyl(node_name: String, r: float, rt: float, h: float, pos: Vector3, mat: Material, parent: Node) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = rt
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = RADIANT
	cm.rings = 1
	return _mesh(node_name, cm, pos, Vector3.ZERO, mat, parent)

func _box(node_name: String, size: Vector3, pos: Vector3, mat: Material, parent: Node, rot := Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _mesh(node_name, bm, pos, rot, mat, parent)

func _mesh(node_name: String, mesh: Mesh, pos: Vector3, rot: Vector3, mat: Material, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _build_intact() -> void:
	_intact = Node3D.new()
	_intact.name = "Intact"
	add_child(_intact)
	_cyl("Foot", 0.33, 0.33, 0.10, Vector3(0, 0.05, 0), _mat_steel, _intact)
	_cyl("Body", 0.28, 0.28, 0.55, Vector3(0, 0.375, 0), _mat_steel, _intact)
	# Schmaler Kupfer-Kragen als Gefahrenband ueber dem Fuss.
	_cyl("Collar", 0.29, 0.29, 0.07, Vector3(0, 0.22, 0), _mat_copper, _intact)
	_cyl("Shoulder", 0.28, 0.10, 0.20, Vector3(0, 0.75, 0), _mat_steel, _intact)
	_cyl("Neck", 0.07, 0.07, 0.06, Vector3(0, 0.88, 0), _mat_steel, _intact)
	_cyl("Valve", 0.055, 0.055, 0.08, Vector3(0, 0.95, 0), _mat_copper, _intact)
	_box("ValveBar", Vector3(0.20, 0.025, 0.025), Vector3(0, 0.945, 0), _mat_steel, _intact)
	# Schmales cyanes Fuellstand-Fenster, kamerazugewandt (+Z), rahmenbuendig.
	_box("LevelWindow", Vector3(0.07, 0.26, 0.02), Vector3(0, 0.45, 0.285), _mat_cyan, _intact)
	# Seitlicher Griff rechts: Pfosten + Querniete (von +Z als Griff lesbar).
	_box("HandlePost", Vector3(0.06, 0.05, 0.06), Vector3(0.29, 0.45, 0), _mat_steel, _intact)
	_box("HandleGrip", Vector3(0.03, 0.34, 0.045), Vector3(0.335, 0.45, 0), _mat_steel, _intact)

func _build_broken() -> void:
	_broken = Node3D.new()
	_broken.name = "Broken"
	add_child(_broken)
	# Kurzer grounded Rumpf mit abgesaegter, unebener Oberkante.
	_cyl("Shell", 0.32, 0.26, 0.34, Vector3(0, 0.17, 0), _mat_steel, _broken)
	# Drei auswaertsgeneigte Zackenplatten auf der Bruchkante — Silhouette
	# klar kantiger als der glatte intakte Zylinder.
	_box("ShardA", Vector3(0.26, 0.14, 0.03), Vector3(0.10, 0.40, 0.12), _mat_steel, _broken, Vector3(0, 0, 0.5))
	_box("ShardB", Vector3(0.22, 0.12, 0.03), Vector3(-0.12, 0.38, -0.08), _mat_steel, _broken, Vector3(0, 0, -0.6))
	_box("ShardC", Vector3(0.20, 0.10, 0.03), Vector3(0.0, 0.42, -0.16), _mat_steel, _broken, Vector3(0.4, 0, 0))
	_cyl("InnerStub", 0.24, 0.24, 0.04, Vector3(0, 0.32, 0), _mat_steel, _broken)
	# Abgerissener Kragenrest, schraeg am Stumpf haeugend (Kupfer bleibt lesbar).
	_box("CollarRemnant", Vector3(0.30, 0.06, 0.02), Vector3(-0.14, 0.24, 0.24), _mat_copper, _broken, Vector3(0, 0.5, 0))
	# Bodentruemmer auesserhalb des Rumpfs (klein, am Fuss).
	_box("Chip", Vector3(0.08, 0.05, 0.06), Vector3(0.24, 0.025, 0.18), _mat_steel, _broken, Vector3(0, 0.8, 0))

func set_broken(b: bool) -> void:
	# Nur Sichtbarkeit der beiden einmal gebauten Gruppen — keine Erzeugung,
	# keine Materialaenderung, kein Timer, keine Animation.
	_intact.visible = not b
	_broken.visible = b

func reset_visual() -> void:
	set_broken(false)

func is_broken() -> bool:
	# Diagnose fuer Smoke-Test/Lead; kein Gameplay-Zugriff.
	return _broken.visible
