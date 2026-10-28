extends "res://modules/loot/supply_crate.gd"
# Reuse the proven one-shot damage/restore lifecycle, without currency rewards.
func _init() -> void:
	crate_id = "security_coolant"
	hit_points = 1
	reward_amount = 0
func _build() -> void:
	_visual = preload("res://modules/visuals/lab_canister_visual.gd").new()
	_visual.name = "CanisterVisual"
	add_child(_visual)
	_collider = CollisionShape3D.new()
	_collider.name = "Collision"
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 1.0
	_collider.shape = shape
	_collider.position.y = 0.5
	add_child(_collider)
