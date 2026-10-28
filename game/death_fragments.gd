extends RefCounted
## Prototype frozen-pose finishing pieces. No skeleton/bone removal or imported asset edits.
static func burst(actor: Node3D, source: MeshInstance3D, impulse: Vector3) -> int:
	# Pose baking requires the real renderer and a registered skinned mesh.
	# A missing bake must retain the original death visual.
	if not is_instance_valid(source) or source.mesh==null or source.skin==null or DisplayServer.get_name()=="headless":return 0
	if not source.get_node_or_null(source.skeleton) is Skeleton3D:return 0
	var baked := source.bake_mesh_from_current_skeleton_pose()
	if baked == null:
		return 0
	# A single diagonal cut follows the horizontal force, rather than four fixed axes.
	var direction := signf(impulse.x) if absf(impulse.x)>0.01 else 1.0
	var normal := Vector3(-0.28*direction,1.0,0.08).normalized()
	var cut := Plane(normal,normal.dot(actor.global_position+Vector3(0,0.93,0)))
	var buckets: Array = [[], []]
	for surface in baked.get_surface_count():
		var arrays := baked.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var ids: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if ids.is_empty():
			for i in verts.size(): ids.append(i)
		for tri in range(0, ids.size()-2, 3):
			var polygon: Array = []
			for k in 3:
				var idx := ids[tri+k]
				polygon.append([source.global_transform*verts[idx], (source.global_basis*normals[idx]).normalized() if not normals.is_empty() else Vector3.UP, uvs[idx] if not uvs.is_empty() else Vector2.ZERO])
			for part in 2:
				var clipped := polygon.duplicate()
				for plane in [cut if part == 0 else Plane(-cut.normal,-cut.d)]:
					clipped = _clip(clipped, plane)
				if clipped.size() >= 3:
					for j in range(1, clipped.size()-1):
						buckets[part].append_array([clipped[0], clipped[j], clipped[j+1]])
	var count := 0
	for part in 2:
		var points: Array = buckets[part]
		if points.is_empty(): continue
		var center := Vector3.ZERO
		for point in points: center += point[0]
		center /= points.size()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in points:
			st.set_normal(point[1]); st.set_uv(point[2]); st.add_vertex(point[0]-center)
		var mesh := MeshInstance3D.new()
		var result := st.commit()
		result.surface_set_material(0, source.get_active_material(0))
		# Seal each planar cut with a dark red cap; the imported animation rig stays intact.
		for plane in [cut if part == 0 else Plane(-cut.normal,-cut.d)]:
			var boundary: Array[Vector3] = []
			var seen := {}
			for point in points:
				var v: Vector3 = point[0]
				if absf(plane.distance_to(v)) < 0.001:
					var key := str(v.snapped(Vector3.ONE*0.002))
					if not seen.has(key):
						seen[key]=true
						boundary.append(v)
			if boundary.size()<3: continue
			var middle := Vector3.ZERO
			for v in boundary: middle+=v
			middle/=boundary.size()
			var u: Vector3 = plane.normal.cross(Vector3.RIGHT).normalized()
			if u.length_squared()<0.1: u=Vector3.FORWARD
			var vaxis: Vector3 = plane.normal.cross(u).normalized()
			boundary.sort_custom(func(a: Vector3,b: Vector3): return atan2((a-middle).dot(vaxis),(a-middle).dot(u)) < atan2((b-middle).dot(vaxis),(b-middle).dot(u)))
			var cap := SurfaceTool.new();cap.begin(Mesh.PRIMITIVE_TRIANGLES)
			for j in boundary.size():
				for v in [middle,boundary[(j+1)%boundary.size()],boundary[j]]:
					cap.set_normal(-plane.normal);cap.add_vertex(v-center)
			var red := StandardMaterial3D.new()
			red.albedo_color=Color(.075,.09,.10) if actor.get("_mechanical")==true else Color(0.22,0.008,0.025)
			red.metallic=.75 if actor.get("_mechanical")==true else 0.0
			red.roughness=0.65
			red.cull_mode=BaseMaterial3D.CULL_DISABLED
			cap.set_material(red);cap.commit(result)
		mesh.mesh = result
		var body := RigidBody3D.new()
		body.add_child(preload("res://modules/combat/debris_pause.gd").new())
		body.name = "FinisherPiece%d" % part
		body.collision_layer = 0
		body.collision_mask = 1
		body.mass = 4.5 if part == 0 else 6.0
		body.linear_damp=0.25
		body.angular_damp=0.9
		var physics := PhysicsMaterial.new()
		physics.bounce=0.05
		physics.friction=0.8
		body.physics_material_override=physics
		body.add_child(mesh)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var bounds := result.get_aabb()
		box.size = bounds.size.clamp(Vector3(0.12,0.12,0.12),Vector3(0.9,1.1,0.6))*0.8
		shape.position = bounds.get_center()
		shape.shape = box
		body.add_child(shape)
		actor.get_tree().current_scene.add_child(body)
		body.global_position = center
		if part == 0 and is_instance_valid(actor._arm_mesh) and actor._arm_mesh.visible:
			var arm_mesh := actor._arm_mesh.bake_mesh_from_current_skeleton_pose() as ArrayMesh
			if arm_mesh:
				var arm := MeshInstance3D.new()
				arm.mesh=arm_mesh
				arm.material_override=actor._arm_mesh.get_active_material(0)
				body.add_child(arm)
				arm.global_transform=actor._arm_mesh.global_transform
		# Upper body follows the blade; legs retain weight and collapse close to contact.
		body.linear_velocity = Vector3(impulse.x*(0.30 if part==0 else 0.08),0.45 if part==0 else 0.05,0.12 if part==0 else -0.12)
		body.angular_velocity = Vector3(0.4 if part==0 else -0.3,0.3*direction,-direction*(2.8 if part==0 else 1.4))
		actor.get_tree().create_timer(5.0).timeout.connect(body.queue_free)
		count += 1
	return count

static func _clip(poly: Array, plane: Plane) -> Array:
	var out: Array=[]
	if poly.is_empty(): return out
	var prev: Array=poly[-1]
	var pd:=plane.distance_to(prev[0])
	for vertex in poly:
		var d:=plane.distance_to(vertex[0])
		if (d>=0)!=(pd>=0):
			var t:=pd/(pd-d)
			out.append([prev[0].lerp(vertex[0],t),prev[1].lerp(vertex[1],t).normalized(),prev[2].lerp(vertex[2],t)])
		if d>=0: out.append(vertex)
		prev=vertex;pd=d
	return out
