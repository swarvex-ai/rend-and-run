extends Node3D
## Compact blast for a kamikaze drone: white-hot core flash, an expanding fireball, a ring of
## sparks and metal shrapnel, a smoke puff that lingers, and a hard light pulse. One node per
## blast, self-cleaning after ~2 s. Damage is the caller's job.

static func blast(parent: Node, pos: Vector3, radius := 1.6) -> Node3D:
	var node: Node3D = (load("res://modules/vfx/explosion.gd") as GDScript).new()
	parent.add_child(node);node.top_level = true;node.global_position = pos
	node._build(radius)
	return node

func _build(radius: float) -> void:
	_fireball(radius)
	_burst(Color(1.0, 0.8, 0.4), 60, 6.0, 14.0, 0.5, Vector3(0.02, 0.18, 0.02), true)   # sparks
	_burst(Color(0.18, 0.18, 0.2), 14, 3.0, 7.0, 1.1, Vector3(0.06, 0.02, 0.05), false) # shrapnel
	_smoke(radius)
	var light := OmniLight3D.new();light.light_color = Color(1.0, 0.6, 0.3);light.light_energy = 9.0
	light.omni_range = radius * 3.5;light.shadow_enabled = false;add_child(light)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(light, "light_energy", 0.0, 0.35)
	get_tree().create_timer(2.2, true, false, true).timeout.connect(queue_free)

func _fireball(radius: float) -> void:
	var ball := MeshInstance3D.new();var sphere := SphereMesh.new()
	sphere.radius = 0.5;sphere.height = 1.0;sphere.radial_segments = 24;sphere.rings = 12
	ball.mesh = sphere
	var m := StandardMaterial3D.new();m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.85, 0.55, 1.0)
	ball.material_override = m;ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ball.scale = Vector3.ONE * 0.3;add_child(ball)
	var tw := create_tween().set_ignore_time_scale(true)  # visible through the hitstop
	tw.tween_property(ball, "scale", Vector3.ONE * radius * 1.6, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(m, "albedo_color", Color(1.0, 0.35, 0.08, 0.0), 0.32)
	tw.tween_callback(ball.queue_free)

func _burst(color: Color, amount: int, speed_min: float, speed_max: float, life: float, size: Vector3, glow: bool) -> void:
	var p := CPUParticles3D.new()
	var mesh := BoxMesh.new();mesh.size = size;p.mesh = mesh
	var m := StandardMaterial3D.new();m.albedo_color = color
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true;m.emission = color;m.emission_energy_multiplier = 6.0
		p.particle_flag_align_y = true
	else:
		m.metallic = 0.9;m.roughness = 0.4
		p.angular_velocity_min = -600.0;p.angular_velocity_max = 600.0
	p.material_override = m
	p.amount = amount;p.one_shot = true;p.explosiveness = 1.0;p.lifetime = life
	p.direction = Vector3.UP;p.spread = 180.0
	p.initial_velocity_min = speed_min;p.initial_velocity_max = speed_max
	p.gravity = Vector3(0, -12, 0);p.damping_min = 1.0;p.damping_max = 3.0
	p.emitting = true;add_child(p)

func _smoke(radius: float) -> void:
	var p := CPUParticles3D.new()
	var quad := QuadMesh.new();quad.size = Vector2(0.9, 0.9);p.mesh = quad
	var m := StandardMaterial3D.new();m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	var g := Gradient.new();g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new();tex.gradient = g;tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5);tex.fill_to = Vector2(1.0, 0.5);tex.width = 64;tex.height = 64
	m.albedo_texture = tex;p.material_override = m
	p.amount = 12;p.one_shot = true;p.explosiveness = 0.9;p.lifetime = 1.8
	p.direction = Vector3.UP;p.spread = 70.0;p.initial_velocity_min = 0.6;p.initial_velocity_max = 1.6
	p.gravity = Vector3(0, 0.6, 0);p.damping_min = 0.8;p.damping_max = 1.4
	p.scale_amount_min = radius * 0.8;p.scale_amount_max = radius * 1.4
	# Smoke rises out of the fireball: invisible at first, then a soft grey that thins out.
	var ramp := Gradient.new();ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 1.0])
	ramp.colors = PackedColorArray([Color(0.5, 0.48, 0.46, 0.0), Color(0.5, 0.48, 0.46, 0.0), Color(0.42, 0.42, 0.44, 0.45), Color(0.38, 0.38, 0.4, 0.0)])
	p.color_ramp = ramp
	p.emitting = true;add_child(p)
