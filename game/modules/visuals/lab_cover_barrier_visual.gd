extends Node3D
## Cover skin: a 2 x 2 stack of Meshy supply cases filling the 1.6 x 1.25 x 0.5 m cover
## (asset_library/meshy/2026-10-23_environment; replaced the H61 lab barrier, which read as
## a cabinet). StaticBody, placement and collider belong to lab_route.
const MODEL = preload("res://assets3d/env/factory_crate_v1/model.glb")
const CASE_SCALE := Vector3(.4, .4, .32)  # 1.9 x 1.54 x 1.56 m model -> 0.76 x 0.62 x 0.5 m
func _ready() -> void:
	if get_child_count() > 0:return
	for row in 2:
		for col in 2:
			var case := MODEL.instantiate() as Node3D
			case.name = "Case%d%d" % [row, col];add_child(case)
			case.scale = CASE_SCALE
			case.position = Vector3(-.39 + col * .78 + (.04 if row == 1 else 0.0), .31 + row * .62, 0)
			case.rotation.y = PI if (row + col) % 2 == 1 else 0.0
