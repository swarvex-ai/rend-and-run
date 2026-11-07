extends SceneTree
const FINISH = preload("res://modules/visuals/humanoid_surface_finish.gd")
const MODEL = preload("res://assets3d/characters/light_humanoid_severable_v1/model.glb")
var failures := 0
func check(label: String, ok: bool) -> void:
	print("HUMANOID FINISH ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize():
	var first=MODEL.instantiate();var second=MODEL.instantiate()
	FINISH.apply(first);FINISH.apply(second)
	var a=first.find_child("char1",true,false) as MeshInstance3D
	var b=second.find_child("char1",true,false) as MeshInstance3D
	var shared=a.get_active_material(0)
	check("two instances share one active material", shared==b.get_active_material(0))
	var count=FINISH._finishes.size()
	for i in 50:FINISH.apply(first)
	check("finish cache stays bounded and shared", FINISH._finishes.size()==count and a.get_active_material(0)==shared)
	# Hit feedback must remain actor-local even though the base finish is shared.
	a.material_override=shared.duplicate();a.material_override.albedo_color=Color(3,3,3)
	check("hit flash stays actor-local", b.get_active_material(0).albedo_color==Color.WHITE)
	first.free();check("shared material survives freeing the first model", b.get_active_material(0)==shared)
	second.free();check("shared material outlives both models", is_instance_valid(shared))
	print("HUMANOID FINISH PASS: shared bounded cache, idempotency, actor-local flash, resource lifetime")
	print("HUMANOID FINISH SUMMARY failures=", failures)
	quit(1 if failures else 0)
