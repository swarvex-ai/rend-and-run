extends Node3D
## Rend's shield. "salvage": a humanoid chest plate he tore off (Meshy, asset_library/meshy/
## 2026-10-22_salvage_shield). "riot": a security robot's riot shield taken from the floor
## (Meshy, asset_library/meshy/2026-10-24_shield). Local +Z is the outward face, origin at the
## grip behind the centre.
const MODELS := {"salvage": ["res://assets3d/props/salvage_shield_v1/model.glb", 0.8], "riot": ["res://assets3d/weapons/riot_shield_v1/model.glb", 1.0]}
var kind := "salvage"

func _ready() -> void:
	set_kind(kind)

func set_kind(k: String) -> void:
	kind = k
	for child in get_children():child.queue_free()
	var model := (load(MODELS[kind][0]) as PackedScene).instantiate() as Node3D
	model.name = "ShieldModel"
	# Sources are centred; scale to the shield's height and keep the face outward.
	var box := AABB();var first := true
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.transform * m.get_aabb();box = b if first else box.merge(b);first = false
	var s: float = MODELS[kind][1] / maxf(box.size.y, 0.001)
	model.scale = Vector3.ONE * s
	model.position = -box.get_center() * s + Vector3(0, 0, 0.05)
	add_child(model)
