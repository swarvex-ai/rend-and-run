extends SceneTree
##诊断: Hero-GLB auf doppelte/statische Meshes pruefen
func _init() -> void:
	var h: Node = load("res://assets3d/characters/hero_rendrun.glb").instantiate()
	_dump(h, 0)
	var s: Node = load("res://assets3d/weapons/hero_sword.glb").instantiate()
	print("--- sword ---")
	_dump(s, 0)
	quit()

func _dump(n: Node, d: int) -> void:
	var extra := ""
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		extra = " MESH skin=%s visible=%s" % [str(mi.skin != null), str(mi.visible)]
	if n is AnimationPlayer:
		extra = " ANIM %s" % str((n as AnimationPlayer).get_animation_list())
	print("  ".repeat(d) + n.name + " (" + n.get_class() + ")" + extra)
	for c in n.get_children():
		_dump(c, d + 1)
