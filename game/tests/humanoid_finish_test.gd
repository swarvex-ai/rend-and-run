extends SceneTree
const FINISH = preload("res://modules/visuals/humanoid_surface_finish.gd")
const MODEL = preload("res://assets3d/characters/light_humanoid_severable_v1/model.glb")
func _initialize():
	var first=MODEL.instantiate();var second=MODEL.instantiate()
	FINISH.apply(first);FINISH.apply(second)
	var a=first.find_child("char1",true,false) as MeshInstance3D
	var b=second.find_child("char1",true,false) as MeshInstance3D
	var shared=a.get_active_material(0)
	assert(shared==b.get_active_material(0))
	var count=FINISH._finishes.size()
	for i in 50:FINISH.apply(first)
	assert(FINISH._finishes.size()==count and a.get_active_material(0)==shared)
	# Hit feedback must remain actor-local even though the base finish is shared.
	a.material_override=shared.duplicate();a.material_override.albedo_color=Color(3,3,3)
	assert(b.get_active_material(0).albedo_color==Color.WHITE)
	first.free();assert(b.get_active_material(0)==shared)
	second.free();assert(is_instance_valid(shared))
	print("HUMANOID FINISH PASS: shared bounded cache, idempotency, actor-local flash, resource lifetime")
	quit()
