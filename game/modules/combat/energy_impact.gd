extends Node
# Owned by the projectile, not its shooter. A WeakRef preserves optional parry
# attribution without retaining a dead enemy or losing late collision handling.
var _source: WeakRef
var _territory_min_x := -10000.0
var _incoming := Vector3.ZERO
var _front := 1.0
var _resolved := false

func configure(source: Node, territory_min_x: float, incoming: Vector3, front: float) -> void:
	_source = weakref(source) if is_instance_valid(source) else null
	_territory_min_x = territory_min_x
	_incoming = incoming
	_front = front

func resolve(collider: Object, point: Vector3, _normal: Vector3) -> void:
	if _resolved:return
	_resolved = true
	var shooter: Node = _source.get_ref() as Node if _source != null else null
	if collider is Node3D and collider.has_method("take_damage") and collider.global_position.x >= _territory_min_x:
		collider.take_damage(1, point - _incoming * 0.3, shooter)
	FX.cut_flash(point, _front, false)
	get_parent().queue_free()
