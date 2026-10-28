extends Node3D
## Original Blender component case. Gameplay owns collision, rewards and damage.
## Both authored states share four materials; switching only changes visibility.
const MODEL: PackedScene = preload("res://assets3d/env/factory_salvage_container_v1/model.glb")
var _broken := false
var _intact_root: Node3D
var _broken_root: Node3D

func _init() -> void:
	var model := MODEL.instantiate()
	add_child(model)
	_intact_root = model.find_child("IntactVisual", true, false) as Node3D
	_broken_root = model.find_child("BrokenVisual", true, false) as Node3D
	assert(_intact_root != null and _broken_root != null)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.material_override = mesh.get_active_material(0)
	_apply_state()

func set_broken(value: bool) -> void:
	_broken = value
	_apply_state()

func is_broken() -> bool:
	return _broken

func _apply_state() -> void:
	_set_subtree_visible(_intact_root, not _broken)
	_set_subtree_visible(_broken_root, _broken)

func _set_subtree_visible(subtree: Node, value: bool) -> void:
	for mesh in subtree.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).visible = value
