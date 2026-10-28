extends RefCounted
## Flying robot parts: enamel panel shards, graphite plates, servo drums, cable ends and
## bolts as small rigid bodies that bounce on the floor and fade after a while. Chips on every
## hit, a full break-up when a robot is destroyed or caught in a blast, an occasional head
## knocked clean off. Capped (MAX_PIECES) so a big fight stays smooth: the oldest go first.

const MAX_PIECES := 160
const LIFETIME := 7.0
static var _live: Array = []
static var _mats := {}

static func _mat(key: String) -> StandardMaterial3D:
	if _mats.has(key):return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"enamel":m.albedo_color = Color(.86, .87, .88);m.metallic = .2;m.roughness = .22
		"graphite":m.albedo_color = Color(.05, .055, .06);m.metallic = .65;m.roughness = .35
		"steel":m.albedo_color = Color(.6, .62, .64);m.metallic = 1.0;m.roughness = .25
		"cable":m.albedo_color = Color(.02, .02, .025);m.roughness = .7
		"amber":
			m.albedo_color = Color(1, .45, .1);m.emission_enabled = true;m.emission = Color(1, .4, .05);m.emission_energy_multiplier = 3.0
	_mats[key] = m
	return m

static func _piece(parent: Node, at: Vector3, mesh: Mesh, mat_key: String, velocity: Vector3, shape_size: Vector3, mass := 0.3) -> RigidBody3D:
	var body := RigidBody3D.new();body.collision_layer = 0;body.collision_mask = 1;body.mass = mass
	body.continuous_cd = false
	var pm := PhysicsMaterial.new();pm.bounce = .3;pm.friction = .7;body.physics_material_override = pm
	var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = shape_size.max(Vector3.ONE * 0.02);shape.shape = box;body.add_child(shape)
	var m := MeshInstance3D.new();m.mesh = mesh;m.material_override = _mat(mat_key);body.add_child(m)
	parent.add_child(body)
	body.global_position = at
	body.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	body.linear_velocity = velocity
	body.angular_velocity = Vector3(randf_range(-14, 14), randf_range(-14, 14), randf_range(-14, 14))
	_track(body)
	return body

static func _track(body: RigidBody3D) -> void:
	_live = _live.filter(func(b): return is_instance_valid(b))
	while _live.size() >= MAX_PIECES:
		var old: RigidBody3D = _live.pop_front()
		if is_instance_valid(old):old.queue_free()
	_live.append(body)
	var tw := body.create_tween()
	tw.tween_interval(LIFETIME);tw.tween_property(body, "scale", Vector3.ONE * 0.01, 0.6);tw.tween_callback(body.queue_free)

static func _random_piece(parent: Node, at: Vector3, dir: Vector3, speed: float) -> void:
	var kind := randi() % 10
	var v := (dir + Vector3(randf_range(-.6, .6), randf_range(.3, 1.2), randf_range(-.5, .5))).normalized() * speed * randf_range(.5, 1.2)
	if kind < 4:
		var s := Vector3(randf_range(.06, .2), randf_range(.012, .025), randf_range(.05, .16))
		var b := BoxMesh.new();b.size = s;_piece(parent, at, b, "enamel", v, s, .25)
	elif kind < 6:
		var s := Vector3(randf_range(.05, .14), randf_range(.02, .04), randf_range(.04, .1))
		var b := BoxMesh.new();b.size = s;_piece(parent, at, b, "graphite", v, s, .3)
	elif kind < 8:
		var r := randf_range(.03, .055);var h := randf_range(.04, .09)
		var c := CylinderMesh.new();c.top_radius = r;c.bottom_radius = r;c.height = h;c.radial_segments = 12
		_piece(parent, at, c, "steel" if kind == 6 else "graphite", v, Vector3(r * 2, h, r * 2), .4)
	elif kind == 8:
		var cap := CapsuleMesh.new();cap.radius = .012;cap.height = randf_range(.12, .3);cap.radial_segments = 6
		_piece(parent, at, cap, "cable", v, Vector3(.024, cap.height, .024), .1)
	else:
		var bolt := CylinderMesh.new();bolt.top_radius = .01;bolt.bottom_radius = .01;bolt.height = .03;bolt.radial_segments = 6
		_piece(parent, at, bolt, "steel", v * 1.3, Vector3(.02, .03, .02), .05)

## A few chips knocked off by a hit (along the blow).
static func chips(parent: Node, at: Vector3, dir: Vector3, count := 4) -> void:
	for i in count:_random_piece(parent, at + Vector3(randf_range(-.1, .1), randf_range(-.1, .1), randf_range(-.08, .08)), dir, 3.5)

## A robot torn apart: a shower of parts over its body height.
static func breakup(parent: Node, centre: Vector3, dir: Vector3, count := 24) -> void:
	for i in count:
		var at := centre + Vector3(randf_range(-.25, .25), randf_range(-.6, .6), randf_range(-.2, .2))
		_random_piece(parent, at, dir, 5.0)

## The round robot head knocked off its neck (stand-in shell with a dark visor and amber eye).
static func head(parent: Node, at: Vector3, dir: Vector3) -> void:
	var shell := SphereMesh.new();shell.radius = .13;shell.height = .26
	var v := (dir.normalized() * 4.0 + Vector3(0, 4.5, randf_range(-.6, .6)))
	var body := _piece(parent, at, shell, "enamel", v, Vector3(.24, .24, .24), 1.2)
	var visor := MeshInstance3D.new();var vm := BoxMesh.new();vm.size = Vector3(.16, .06, .02);visor.mesh = vm
	visor.material_override = _mat("graphite");visor.position = Vector3(0, .01, .125);body.add_child(visor)
	var eye := MeshInstance3D.new();var em := SphereMesh.new();em.radius = .022;em.height = .044;eye.mesh = em
	eye.material_override = _mat("amber");eye.position = Vector3(.03, .01, .135);body.add_child(eye)

## A spent magazine dropped by a reload (dark box, dull clack on the floor).
static func magazine(parent: Node, at: Vector3, velocity: Vector3) -> void:
	var b := BoxMesh.new();b.size = Vector3(.035, .13, .07)
	_piece(parent, at, b, "graphite", velocity, b.size, .25)
