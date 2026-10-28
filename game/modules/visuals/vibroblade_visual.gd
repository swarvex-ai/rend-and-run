extends Node3D
## H23 — Schwere Vibroklinge (Rend), reines Visual-Modul ohne Runtime-Logik.
## Geometrie wird EINMAL in _init() gebaut. Keine Lights, Physik, Timer, Audio,
## Kollision, Datei-IO oder Per-Frame-Logik; kein class_name.
##
## Autorings-Achsen — gemessen an game/assets3d/weapons/hero_sword.glb (read-only):
##   Root 'hero_sword' Identitaet am Hand-Knochen (BoneAttachment hand_r /
##   mixamorig_RightHand); 'sword_hilt' Bounds y[-0.144, +0.134] — das
##   Hand-/Grip-Pivot liegt im URSPRUNG (Griff haengt nach unten), das
##   'sword_blade'-Kind (Y+0.13) laeuft y[0.13, 1.015], d.h. Klingenspitze
##   zeigt in +Y. Klingenbreite in X (±0.038), Klingenbauch duenn in Z (±0.009).
##   Reichweite Pivot->Spitze: 1.015 m.
## Diese Klinge folgt derselben Konvention: Griff unter dem Ursprung, Spitze
## +Y, Breite X, Duemme Z; Spitze bei ~1.167 (= 1.015 * 1.15), Blatt deutlich
## breiter als die Referenz (x[-0.075, +0.060]).
##
## Winding (Codex-Regel nach H22-Review): Godot-Frontseite ist IM UHRZEIGERSINN
## von aussen gesehen, nach aussen weisende Normalen, CULL_BACK — kein
## CULL_DISABLED zum Kaschieren von Windungsfehlern.

# Budgets: 11 MeshInstance3D, 4 geteilte StandardMaterial3D, ~160 Dreiecke.

static var _mat_titanium: StandardMaterial3D = null
static var _mat_edge: StandardMaterial3D = null
static var _mat_energy: StandardMaterial3D = null
static var _mat_grip: StandardMaterial3D = null
static var _blade_mesh: ArrayMesh = null


static func _ti_mat() -> StandardMaterial3D:
	if _mat_titanium == null:
		_mat_titanium = StandardMaterial3D.new()
		_mat_titanium.albedo_color = Color(0.10, 0.115, 0.15)   # dunkles Titan
		_mat_titanium.metallic = 0.75
		_mat_titanium.roughness = 0.38
		_mat_titanium.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_titanium


static func _edge_mat() -> StandardMaterial3D:
	if _mat_edge == null:
		_mat_edge = StandardMaterial3D.new()
		_mat_edge.albedo_color = Color(0.85, 0.88, 0.92)        # blasser Schliff
		_mat_edge.metallic = 0.9
		_mat_edge.roughness = 0.15
		_mat_edge.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_edge


static func _cyan_mat() -> StandardMaterial3D:
	if _mat_energy == null:
		_mat_energy = StandardMaterial3D.new()
		_mat_energy.albedo_color = Color(0.15, 0.55, 0.62)      # zyan Energiekanal
		_mat_energy.emission_enabled = true
		_mat_energy.emission = Color(0.10, 0.50, 0.60)
		_mat_energy.emission_energy_multiplier = 0.9
		_mat_energy.roughness = 0.4
		_mat_energy.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_energy


static func _wrap_mat() -> StandardMaterial3D:
	if _mat_grip == null:
		_mat_grip = StandardMaterial3D.new()
		_mat_grip.albedo_color = Color(0.07, 0.075, 0.09)       # matte Wickel-Optik
		_mat_grip.metallic = 0.05
		_mat_grip.roughness = 0.92
		_mat_grip.cull_mode = BaseMaterial3D.CULL_BACK
	return _mat_grip


func _init() -> void:
	# --- Griff (Grip-Pivot = Ursprung; Segmente = Wickel-Optik), y-reich: -0.189..0.011
	_add_box("Grip1", Vector3(0.048, 0.044, 0.048), Vector3(0.0, -0.011, 0.0), _wrap_mat())
	_add_box("Grip2", Vector3(0.050, 0.044, 0.050), Vector3(0.0, -0.052, 0.0), _wrap_mat())
	_add_box("Grip3", Vector3(0.048, 0.044, 0.048), Vector3(0.0, -0.093, 0.0), _wrap_mat())
	_add_box("Grip4", Vector3(0.050, 0.044, 0.050), Vector3(0.0, -0.134, 0.0), _wrap_mat())
	_add_box("Pommel", Vector3(0.062, 0.030, 0.062), Vector3(0.0, -0.171, 0.0), _ti_mat())
	# --- Parierstange (massiv, Winkel-Optik), y 0.010..0.070 — ueberlappt Gripspitze
	_add_box("Guard", Vector3(0.30, 0.060, 0.056), Vector3(0.0, 0.040, 0.0), _ti_mat())
	_add_box("GuardLug", Vector3(0.070, 0.075, 0.048), Vector3(-0.160, 0.035, 0.0), _ti_mat())
	# --- Klemmhals zwischen Parier und Blatt, y 0.062..0.107
	_add_box("Collar", Vector3(0.095, 0.045, 0.050), Vector3(0.0, 0.085, 0.0), _ti_mat())
	# --- Blatt: winklig, breit, asymmetrisch (ArrayMesh), y 0.10..1.167
	_add_mesh("Blade", _blade_array_mesh(), Vector3.ZERO, _ti_mat())
	# --- Schmaler blasser Schliff entlang der Schneidkante (-X-Seite), beidseitig sichtbar
	_add_box("EdgeLower", Vector3(0.014, 0.310, 0.026), Vector3(-0.072, 0.270, 0.0), _edge_mat())
	_add_box("EdgeUpper", Vector3(0.014, 0.280, 0.026), Vector3(-0.062, 0.570, 0.0), _edge_mat())
	# --- Zyaner Energiekanal laengs des Blattbauchs, dezent
	_add_box("EnergyChannel", Vector3(0.018, 0.620, 0.026), Vector3(0.004, 0.550, 0.0), _cyan_mat())


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
# ArrayMesh-Blatt: winkliges, asymmetrisches Profil in der XY-Ebene
# (X = Breite, Y = Laenge), in Z (±0.011) extrudiert. Profil gegen den
# Uhrzeigersinn von +Z aus gesehen; _add_tri_out orientiert Normalen nach
# aussen und liefert die Uhrzeigersinn-Windung fuer Godots Frontseite.

func _blade_array_mesh() -> ArrayMesh:
	if _blade_mesh != null:
		return _blade_mesh
	# Kontur (Uhrzeigersinn von +Z): Basis breit, Schneide (-X) baucht aus,
	# Ruecken (+X) knickt ab, Spitze asymmetrisch ueber die Mitte gelehnt.
	var profile: Array[Vector2] = [
		Vector2(-0.075, 0.100),   # Basis Schneidenseite
		Vector2(0.060, 0.100),    # Basis Rueckenseite
		Vector2(0.060, 0.300),    # Ruecken gerade bis Knick
		Vector2(0.030, 0.620),    # Ruecken-Ziehlinie
		Vector2(-0.020, 1.167),   # Spitze (asymmetrisch ueber der Mitte)
		Vector2(-0.058, 0.720),   # Schneidenausbauch oben
		Vector2(-0.075, 0.420),   # breitester Schneidepunkt
	]
	var dz := 0.011
	var inside := Vector3(-0.005, 0.45, 0.0)   # garantierter Innenpunkt des Volumens
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var n := profile.size()
	for i in n:
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[(i + 1) % n]
		# Mantel-Quads (2 Dreiecke), je Seite Z=-dz und Z=+dz.
		var p0f := Vector3(a.x, a.y, dz)
		var p1f := Vector3(b.x, b.y, dz)
		var p0k := Vector3(a.x, a.y, -dz)
		var p1k := Vector3(b.x, b.y, -dz)
		_add_tri_out(verts, normals, p0f, p1f, Vector3(a.x, a.y, -dz), inside)
		_add_tri_out(verts, normals, p1f, p1k, Vector3(a.x, a.y, -dz), inside)
		# Kappen: Faelcher vom Profil-Schwerpunkt (liegt innerhalb des Volumens;
		# Profil ist sternfoermig dazu — minimale Ueberlappung ist unsichtbar).
	_add_cap_fans(verts, normals, profile, dz, inside)
	var arr := Array()
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	am.custom_aabb = AABB(Vector3(-0.075, 0.100, -dz), Vector3(0.135, 1.067, 2.0 * dz))
	_blade_mesh = am
	return am


func _add_cap_fans(verts: PackedVector3Array, normals: PackedVector3Array, profile: Array[Vector2], dz: float, inside: Vector3) -> void:
	# Schwerpunkt des Siebenecks (sternfoermig dazu): Anker beider Kappen.
	var anchor := Vector2(-0.0111, 0.4896)
	var n := profile.size()
	for i in n:
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[(i + 1) % n]
		_add_tri_out(verts, normals, Vector3(a.x, a.y, dz), Vector3(b.x, b.y, dz), Vector3(anchor.x, anchor.y, dz), inside)
		_add_tri_out(verts, normals, Vector3(a.x, a.y, -dz), Vector3(b.x, b.y, -dz), Vector3(anchor.x, anchor.y, -dz), inside)


## Godot-Front = Uhrzeigersinn von aussen, Normalen nach aussen, CULL_BACK.
## Bedingter Swap: hat die RIGHT-Hand-Normale (p1-p0)x(p2-p0) schon nach
## aussen, emittieren wir (p0,p2,p1); zeigt sie nach innen, emittieren wir
## (p0,p1,p2). In beiden Faellen zeigt die RIGHT-Hand-Normale der EMITTERTEN
## Reihenfolge gegen die geschriebene Aussen-Normale — das ist Godots
## CLOCKWISE-Frontseite bei Outward-Normalen, konsistent fuer ALLE Faces.
func _add_tri_out(verts: PackedVector3Array, normals: PackedVector3Array, p0: Vector3, p1: Vector3, p2: Vector3, inside: Vector3) -> void:
	var nrm := (p1 - p0).cross(p2 - p0)
	if nrm.length_squared() < 1e-12:
		return
	var tri_center := (p0 + p1 + p2) * (1.0 / 3.0)
	if nrm.dot(tri_center - inside) >= 0.0:
		# RIGHT-Hand zeigt nach aussen -> Swap fuer CLOCKWISE-Front.
		verts.append(p0)
		verts.append(p2)
		verts.append(p1)
		nrm = nrm.normalized()
	else:
		# RIGHT-Hand zeigt nach innen -> Reihenfolge behalten, Normale spiegeln.
		verts.append(p0)
		verts.append(p1)
		verts.append(p2)
		nrm = (-nrm).normalized()
	normals.append(nrm)
	normals.append(nrm)
	normals.append(nrm)
