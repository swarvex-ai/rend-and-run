extends Node3D
## Foreground depth layer between the camera and the floor strip (as in Dead Cells): sparse
## dark pipe bundles rising from the front deck to the ceiling, sagging cable runs between
## them and a long service duct along the top edge. Thin and widely spaced so they frame
## the fight without hiding it; a bundle fades out while Rend is behind it. Visual only.

const Z := 3.05               # in front of the floor strip, behind the camera
const TOP := 4.6
const BUNDLES := [6.5, 19.0, 31.5, 44.0, 57.5, 70.0]
const FADE_RANGE := 1.4       # |dx| from Rend at which a bundle turns see-through
var _bundles := []            # [x, materials]

func build(from_x: float, to_x: float) -> void:
	var dark := StandardMaterial3D.new();dark.albedo_color = Color(.035, .04, .045);dark.metallic = .7;dark.roughness = .45
	var steel := StandardMaterial3D.new();steel.albedo_color = Color(.11, .13, .15);steel.metallic = .85;steel.roughness = .3
	var amber := StandardMaterial3D.new();amber.albedo_color = Color(1, .45, .1);amber.emission_enabled = true
	amber.emission = Color(1, .45, .1);amber.emission_energy_multiplier = 3.0
	# Service duct along the top: a continuous frame edge.
	_box(Vector3((from_x + to_x) * .5, TOP, Z - .1), Vector3(to_x - from_x, .32, .42), dark)
	for i in BUNDLES.size():
		var x: float = BUNDLES[i]
		if x < from_x or x > to_x:continue
		# Own materials per bundle so it can fade on its own.
		var pipe_dark := dark.duplicate() as StandardMaterial3D;var pipe_steel := steel.duplicate() as StandardMaterial3D
		for m in [pipe_dark, pipe_steel]:m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		for k in 2:
			_pipe(Vector3(x + k * .2 - .1, 0, Z + k * .1), TOP, [.07, .05][k], pipe_steel if k == 1 else pipe_dark)
		for y in [1.1, 2.6, 3.9]:_box(Vector3(x, y, Z + .05), Vector3(.5, .06, .24), pipe_dark)  # clamps
		_box(Vector3(x + .2, 1.6, Z + .2), Vector3(.04, .12, .02), amber)  # status lamp
		_bundles.append([x, [pipe_dark, pipe_steel]])
		# A sagging cable run to the next bundle.
		if i + 1 < BUNDLES.size():_cable(Vector3(x + .3, 3.75, Z + .15), Vector3(BUNDLES[i + 1] - .3, 3.75, Z + .15), .9, dark)

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:return
	for bundle in _bundles:
		var target := 0.3 if absf(player.global_position.x - bundle[0]) < FADE_RANGE else 1.0
		for m in bundle[1]:
			m.albedo_color.a = move_toward(m.albedo_color.a, target, delta * 4.0)

func _box(at: Vector3, size: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new();var b := BoxMesh.new();b.size = size;m.mesh = b
	m.material_override = mat;m.position = at;m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(m)

func _pipe(base: Vector3, height: float, radius: float, mat: Material) -> void:
	var m := MeshInstance3D.new();var c := CylinderMesh.new()
	c.top_radius = radius;c.bottom_radius = radius;c.height = height;c.radial_segments = 14;m.mesh = c
	m.material_override = mat;m.position = base + Vector3(0, height * .5, 0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(m)

# A catenary-ish sag made of short segments.
func _cable(a: Vector3, b: Vector3, sag: float, mat: Material) -> void:
	var steps := 18;var prev := a
	for s in range(1, steps + 1):
		var t := float(s) / steps
		var p := a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		var m := MeshInstance3D.new();var c := CylinderMesh.new()
		c.top_radius = .025;c.bottom_radius = .025;c.height = prev.distance_to(p);c.radial_segments = 6;m.mesh = c
		m.material_override = mat;m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m);m.position = (prev + p) * .5
		m.basis = Basis(Quaternion(Vector3.UP, (p - prev).normalized()))
		prev = p
