extends Node3D
## Brief directional dash cue. No gameplay, collision or per-frame script work.
const MAX_BURSTS := 4
static var _mesh: CylinderMesh
static var _material: StandardMaterial3D
static var _shrink: Curve
var _active: Array[CPUParticles3D] = []

static func _resources() -> void:
	if _mesh != null: return
	_mesh = CylinderMesh.new()
	_mesh.height = 0.10
	_mesh.top_radius = 0.0
	_mesh.bottom_radius = 0.006
	_mesh.radial_segments = 4
	_mesh.rings = 1
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color(0.42, 0.65, 0.76, 0.65)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shrink = Curve.new()
	_shrink.add_point(Vector2(0, 1))
	_shrink.add_point(Vector2(1, 0))

func emit_dash(world_pos: Vector3, direction: Vector3) -> void:
	_resources()
	while _active.size() >= MAX_BURSTS:
		_active.pop_front().queue_free()
	var p := CPUParticles3D.new()
	p.name = "DashBurst"
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 10
	p.lifetime = 0.20
	p.local_coords = false
	p.mesh = _mesh
	p.material_override = _material
	p.particle_flag_align_y = true
	p.direction = -direction.normalized() if direction.length_squared() > 0.0001 else Vector3.LEFT
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.04, 0.30, 0.04)
	p.spread = 15.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.scale_amount_min = 0.75
	p.scale_amount_max = 1.2
	p.scale_amount_curve = _shrink
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(p)
	p.top_level = true
	p.global_transform = Transform3D(Basis.IDENTITY, world_pos)
	_active.append(p)
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.4
	timer.autostart = true
	timer.timeout.connect(_retire.bind(p))
	p.add_child(timer) # Retiring a burst also destroys its timer.
	p.emitting = true
	p.restart()

func _retire(p: CPUParticles3D) -> void:
	_active.erase(p)
	if is_instance_valid(p): p.queue_free()

func clear() -> void:
	while not _active.is_empty(): _active.pop_back().queue_free()

func active_count() -> int:
	return _active.size()
