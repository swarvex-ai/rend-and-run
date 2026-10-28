extends RefCounted
## Side-plane blade contact. Authored blade endpoints follow the evaluated hand.
## Small tolerance for readability; Z projection is intentional in the 2.5D lane.
const RADIUS := 0.10
const SAMPLE_SPACING := 0.08
var _previous_base := Vector3.ZERO
var _previous_tip := Vector3.ZERO
var _has_previous := false
var _shape := CapsuleShape3D.new()

func clear() -> void:
	_has_previous = false

func query(space: PhysicsDirectSpaceState3D, blade_base: Vector3, blade_tip: Vector3, lane_z: float, owner_rid: RID) -> Array:
	blade_base.z = lane_z
	blade_tip.z = lane_z
	var steps := 1
	if _has_previous:
		var travel := maxf(blade_base.distance_to(_previous_base), blade_tip.distance_to(_previous_tip))
		# Do not connect teleports or respawns with a damaging sweep.
		if travel > 2.0:
			clear()
		else:
			steps = clampi(int(ceil(travel / SAMPLE_SPACING)), 1, 24)
	var bodies: Array = []
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _shape
	q.collision_mask = 2
	q.exclude = [owner_rid]
	q.margin = 0.0
	for i in range(1, steps + 1):
		var weight := float(i) / steps
		var a := _previous_base.lerp(blade_base, weight) if _has_previous else blade_base
		var b := _previous_tip.lerp(blade_tip, weight) if _has_previous else blade_tip
		var segment := b - a
		if segment.length_squared() < 0.000001:
			continue
		_shape.radius = RADIUS
		_shape.height = segment.length() + 2.0 * RADIUS
		q.transform = Transform3D(Basis(Quaternion(Vector3.UP, segment.normalized())), (a + b) * 0.5)
		for hit in space.intersect_shape(q, 32):
			if not bodies.has(hit.collider):
				bodies.append(hit.collider)
	_previous_base = blade_base
	_previous_tip = blade_tip
	_has_previous = true
	return bodies
