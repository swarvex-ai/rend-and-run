extends RefCounted
## Reuse one baked tangent map across the identical body/arm UV atlas.
## Original cut geometry, skeletons, materials and flash behavior stay intact.
const SOURCE: PackedScene = preload("res://assets3d/characters/light_humanoid_baked_v1/model.glb")
static var _normal: Texture2D
# Retain the small set of immutable atlas finishes across actor lifetimes.
# Hit flashes duplicate their material separately; they never mutate these.
static var _finishes: Dictionary = {}

static func apply(model: Node) -> void:
	if _normal == null:
		var source := SOURCE.instantiate()
		var body := source.find_child("char1", true, false) as MeshInstance3D
		assert(body != null)
		_normal = (body.get_active_material(0) as StandardMaterial3D).normal_texture
		source.free()
	assert(_normal != null)
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for node in meshes:
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			# Untextured metallic cut caps must not inherit the body atlas.
			if original == null or original.normal_texture == null or original in _finishes.values():
				continue
			if not _finishes.has(original):
				var finish := original.duplicate() as StandardMaterial3D
				finish.normal_texture = _normal
				finish.normal_enabled = true
				_finishes[original] = finish
			mesh.set_surface_override_material(surface, _finishes[original])
