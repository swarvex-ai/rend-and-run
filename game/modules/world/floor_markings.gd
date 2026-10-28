extends Node3D
## Worn safety paint on the factory floor (materials/floor_paint.gdshader): yellow walkway
## lines along both edges of the floor strip and black-yellow hazard fields in front of
## doors and gates. Visual only.

const LINE_Y := 0.004
const LINE_WIDTH := 0.09
const EDGES := [-1.18, 1.42]           # z of the walkway lines (strip is -1.05..1.25)
const HAZARDS := [16.5, 70.0, 77.0]    # x of door / arena gate / exit lock

func build(from_x: float, to_x: float) -> void:
	for z in EDGES:
		_quad(Vector3((from_x + to_x) * 0.5, LINE_Y, z), Vector2(to_x - from_x, LINE_WIDTH), false, 0.5)
	for x in HAZARDS:
		_quad(Vector3(x, LINE_Y + 0.001, 0.12), Vector2(1.1, 2.45), true, 0.38)

func _quad(at: Vector3, size: Vector2, hazard: bool, wear: float) -> void:
	var mesh := MeshInstance3D.new();mesh.name = "HazardField" if hazard else "WalkwayLine"
	var plane := PlaneMesh.new();plane.size = size;mesh.mesh = plane
	var paint := ShaderMaterial.new();paint.shader = preload("res://materials/floor_paint.gdshader")
	paint.set_shader_parameter("hazard", hazard);paint.set_shader_parameter("wear", wear)
	paint.set_shader_parameter("size", size)
	mesh.material_override = paint
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh);mesh.position = at
