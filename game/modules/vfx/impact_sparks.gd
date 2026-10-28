extends Node3D
## Heavy metal impact for a blow landing on a robot: a burst of stretched glowing sparks
## thrown along the blow, a short white-hot flash at the contact point and a few dark
## metal chips that drop to the floor. Readable from the gameplay camera (the old contact
## sparks were centimetre-sized). Self-cleaning; one node per impact.

static var _spark_mesh: BoxMesh
static var _chip_mesh: BoxMesh
static var _flash_mesh: QuadMesh
static var _spark_mat: StandardMaterial3D
static var _chip_mat: StandardMaterial3D
static var _flash_mat: StandardMaterial3D

## direction: where the weapon travels (sparks fly on along it). heavy: bigger burst.
static func burst(parent: Node, pos: Vector3, direction: Vector3, heavy := false) -> Node3D:
	_ensure_resources()
	var node: Node3D = (load("res://modules/vfx/impact_sparks.gd") as GDScript).new()
	parent.add_child(node)
	node.top_level = true
	node.global_position = pos
	var dir := direction.normalized() if direction.length() > 0.01 else Vector3.UP
	node.add_child(_sparks(dir, 90 if heavy else 60, 1.25 if heavy else 1.05))
	node.add_child(_sparks(-dir, 24 if heavy else 14, 0.6))  # a back-spray off the plating
	node._arc()
	node.add_child(_chips(dir, 8 if heavy else 5))
	node._flash(0.62 if heavy else 0.46)
	node.get_tree().create_timer(1.2).timeout.connect(node.queue_free)
	return node

static func _ensure_resources() -> void:
	if _spark_mesh:return
	_spark_mesh = BoxMesh.new();_spark_mesh.size = Vector3(0.016, 0.16, 0.016)
	_chip_mesh = BoxMesh.new();_chip_mesh.size = Vector3(0.035, 0.012, 0.025)
	_flash_mesh = QuadMesh.new();_flash_mesh.size = Vector2(1, 1)
	_spark_mat = StandardMaterial3D.new()
	_spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spark_mat.vertex_color_use_as_albedo = true
	_spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_spark_mat.emission_enabled = true;_spark_mat.emission = Color(1.0, 0.62, 0.22);_spark_mat.emission_energy_multiplier = 6.0
	_chip_mat = StandardMaterial3D.new()
	_chip_mat.albedo_color = Color(0.32, 0.33, 0.35);_chip_mat.metallic = 0.9;_chip_mat.roughness = 0.35
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_flash_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_flash_mat.albedo_color = Color(1.0, 0.9, 0.7)
	_flash_mat.albedo_texture = _radial_texture()

static func _radial_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 0.8, 0.5, 0.7), Color(1, 0.5, 0.2, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g;tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5);tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64;tex.height = 64
	return tex

static func _sparks(dir: Vector3, amount: int, speed_scale: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = _spark_mesh;p.material_override = _spark_mat
	p.amount = amount;p.one_shot = true;p.explosiveness = 1.0;p.lifetime = 0.42
	p.direction = dir;p.spread = 55.0
	p.initial_velocity_min = 4.0 * speed_scale;p.initial_velocity_max = 10.0 * speed_scale
	p.gravity = Vector3(0, -14, 0);p.damping_min = 2.0;p.damping_max = 5.0
	p.particle_flag_align_y = true  # streaks point along their flight
	p.scale_amount_min = 0.6;p.scale_amount_max = 1.4
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.97, 0.85, 1), Color(1, 0.7, 0.3, 1), Color(0.9, 0.3, 0.05, 0)])
	p.color_ramp = ramp
	p.emitting = true
	return p

static func _chips(dir: Vector3, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = _chip_mesh;p.material_override = _chip_mat
	p.amount = amount;p.one_shot = true;p.explosiveness = 1.0;p.lifetime = 0.9
	p.direction = (dir + Vector3.UP * 0.6).normalized();p.spread = 40.0
	p.initial_velocity_min = 2.0;p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, -16, 0)
	p.angular_velocity_min = -720.0;p.angular_velocity_max = 720.0
	p.emitting = true
	return p

# A brief electric crackle at the contact: a few jagged cyan-white filaments.
func _arc() -> void:
	var mat := StandardMaterial3D.new();mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(.75, .9, 1.0);mat.emission_enabled = true;mat.emission = Color(.5, .8, 1.0);mat.emission_energy_multiplier = 8.0
	for i in 3:
		var seg := MeshInstance3D.new();var b := BoxMesh.new();b.size = Vector3(.012, randf_range(.12, .3), .012);seg.mesh = b
		seg.material_override = mat;seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(seg);seg.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU);seg.position = Vector3(randf_range(-.08, .08), randf_range(-.08, .08), .05)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.07);tw.tween_callback(func():
		for c in get_children():
			if c is MeshInstance3D and c.material_override == mat:c.queue_free())

func _flash(size: float) -> void:
	var quad := MeshInstance3D.new()
	quad.mesh = _flash_mesh;quad.material_override = _flash_mat.duplicate()
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.scale = Vector3.ONE * size
	add_child(quad)
	var tw := create_tween().set_ignore_time_scale(true)  # visible through the hitstop
	tw.tween_property(quad, "scale", Vector3.ONE * size * 1.6, 0.09)
	tw.parallel().tween_property(quad.material_override, "albedo_color:a", 0.0, 0.09)
	tw.tween_callback(quad.queue_free)
