extends RefCounted
## Firearm effects: muzzle flash with a light pop, ejected brass casings, bullet holes with a
## puff of sparks on walls and props, and smoke/spark leaks from damaged robots.

static var _flash_mat: StandardMaterial3D
static var _brass_mat: StandardMaterial3D
static var _hole_tex: GradientTexture2D

static func _ensure() -> void:
	if _flash_mat:return
	_flash_mat = StandardMaterial3D.new();_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;_flash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_flash_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var g := Gradient.new();g.offsets = PackedFloat32Array([0, .3, 1])
	g.colors = PackedColorArray([Color(1, 1, .9, 1), Color(1, .7, .3, .8), Color(1, .4, .1, 0)])
	var t := GradientTexture2D.new();t.gradient = g;t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(.5, .5);t.fill_to = Vector2(1, .5);t.width = 64;t.height = 64
	_flash_mat.albedo_texture = t
	_brass_mat = StandardMaterial3D.new();_brass_mat.albedo_color = Color(.78, .58, .22);_brass_mat.metallic = 1.0;_brass_mat.roughness = .3
	var h := Gradient.new();h.offsets = PackedFloat32Array([0, .35, .6, 1])
	h.colors = PackedColorArray([Color(0, 0, 0, 1), Color(.05, .05, .05, .95), Color(.2, .18, .15, .5), Color(0, 0, 0, 0)])
	_hole_tex = GradientTexture2D.new();_hole_tex.gradient = h;_hole_tex.fill = GradientTexture2D.FILL_RADIAL
	_hole_tex.fill_from = Vector2(.5, .5);_hole_tex.fill_to = Vector2(1, .5);_hole_tex.width = 32;_hole_tex.height = 32

static func muzzle_flash(parent: Node, at: Vector3, color: Color, size := 0.22) -> void:
	_ensure()
	var q := MeshInstance3D.new();var quad := QuadMesh.new();quad.size = Vector2.ONE * size;q.mesh = quad
	var m := _flash_mat.duplicate() as StandardMaterial3D;m.albedo_color = color.lightened(0.4);q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(q);q.global_position = at;q.rotation.z = randf() * TAU
	var tw := q.create_tween().set_ignore_time_scale(true)
	tw.tween_property(q, "scale", Vector3.ONE * 1.5, 0.05);tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.06)
	tw.tween_callback(q.queue_free)

static func casing(parent: Node, at: Vector3, facing: float) -> void:
	_ensure()
	var body := RigidBody3D.new();body.collision_layer = 0;body.collision_mask = 1;body.mass = 0.02
	var pm := PhysicsMaterial.new();pm.bounce = 0.45;pm.friction = .6;body.physics_material_override = pm
	var shape := CollisionShape3D.new();var cap := CylinderShape3D.new();cap.radius = .008;cap.height = .025;shape.shape = cap;body.add_child(shape)
	var mesh := MeshInstance3D.new();var c := CylinderMesh.new();c.top_radius = .006;c.bottom_radius = .007;c.height = .025;c.radial_segments = 8
	mesh.mesh = c;mesh.material_override = _brass_mat;mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;body.add_child(mesh)
	parent.add_child(body);body.global_position = at
	body.linear_velocity = Vector3(-facing * randf_range(.8, 1.6), randf_range(1.8, 2.8), randf_range(.3, .9))
	body.angular_velocity = Vector3(randf_range(-20, 20), randf_range(-20, 20), randf_range(-20, 20))
	body.get_tree().create_timer(2.5).timeout.connect(body.queue_free)

static func bullet_hole(parent: Node, at: Vector3, normal: Vector3) -> void:
	_ensure()
	var d := Decal.new();d.texture_albedo = _hole_tex;d.size = Vector3(.09, .1, .09)
	parent.add_child(d);d.global_position = at
	var n := normal.normalized() if normal.length() > 0.1 else Vector3.UP
	var side := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	d.global_basis = Basis(side, n, side.cross(n)).orthonormalized()
	var tw := d.create_tween();tw.tween_interval(7.0);tw.tween_property(d, "modulate:a", 0.0, 1.5);tw.tween_callback(d.queue_free)

## Leaking smoke and the odd spark from a badly damaged robot (attach to its chest).
static func damage_leak(attach: Node3D) -> void:
	var smoke := CPUParticles3D.new();smoke.name = "DamageSmoke"
	var quad := QuadMesh.new();quad.size = Vector2(.25, .25);smoke.mesh = quad
	var m := StandardMaterial3D.new();m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES;m.vertex_color_use_as_albedo = true
	_ensure();m.albedo_texture = _flash_mat.albedo_texture
	smoke.material_override = m
	smoke.amount = 14;smoke.lifetime = 1.4;smoke.direction = Vector3.UP;smoke.spread = 25
	smoke.initial_velocity_min = .3;smoke.initial_velocity_max = .7;smoke.gravity = Vector3(0, .4, 0)
	smoke.scale_amount_min = .8;smoke.scale_amount_max = 1.8
	var ramp := Gradient.new();ramp.colors = PackedColorArray([Color(.25, .25, .27, .55), Color(.2, .2, .22, 0)]);smoke.color_ramp = ramp
	attach.add_child(smoke)
	var sparks := CPUParticles3D.new();sparks.name = "DamageSparks"
	var b := BoxMesh.new();b.size = Vector3(.008, .04, .008);sparks.mesh = b
	var sm := StandardMaterial3D.new();sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;sm.vertex_color_use_as_albedo = true
	sm.emission_enabled = true;sm.emission = Color(1, .7, .3);sm.emission_energy_multiplier = 5
	sparks.material_override = sm;sparks.particle_flag_align_y = true
	sparks.amount = 10;sparks.lifetime = .4;sparks.explosiveness = .8;sparks.direction = Vector3.UP;sparks.spread = 80
	sparks.initial_velocity_min = 1.2;sparks.initial_velocity_max = 2.6;sparks.gravity = Vector3(0, -9.8, 0)
	var sr := Gradient.new();sr.colors = PackedColorArray([Color(1, .95, .7), Color(1, .4, .1, 0)]);sparks.color_ramp = sr
	attach.add_child(sparks)
