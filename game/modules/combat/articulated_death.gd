extends SkeletonModifier3D
## World-metre rigid proxies keep imported centimetre skeleton transforms intact.
## Bone names follow the Meshy robot rig; a Mixamo rig (Rend) passes its prefix and the
## few differing names are translated.
const MIXAMO_NAMES := {"Spine02":"Spine","neck":"Neck"}
var bindings: Array = []
var physics_root: Node3D
## [bone, child bone (limb end), parent bone, capsule radius, mass, swing limit deg],
## parents first. Shared with hit_physics.gd.
static func limb_specs(mixamo_prefix := "") -> Array:
	var specs=[
		["Hips","Spine02","",.14,7.0,25.0],
		["Spine02","neck","Hips",.17,10.0,25.0],
		["Head","head_end","Spine02",.11,3.0,25.0],
		["LeftArm","LeftForeArm","Spine02",.065,2.0,60.0],
		["LeftForeArm","LeftHand","LeftArm",.055,1.5,65.0],
		["RightArm","RightForeArm","Spine02",.065,2.0,60.0],
		["RightForeArm","RightHand","RightArm",.055,1.5,65.0],
		["LeftUpLeg","LeftLeg","Hips",.085,4.0,45.0],
		["LeftLeg","LeftFoot","LeftUpLeg",.07,3.0,55.0],
		["RightUpLeg","RightLeg","Hips",.085,4.0,45.0],
		["RightLeg","RightFoot","RightUpLeg",.07,3.0,55.0]]
	if not mixamo_prefix.is_empty():
		for spec in specs:
			for i in 3:
				if spec[i]!="":spec[i]=mixamo_prefix+MIXAMO_NAMES.get(spec[i],spec[i])
	return specs

func build(actor: CharacterBody3D, impulse: Vector3, mixamo_prefix := "") -> bool:
	var sk=get_skeleton()
	var specs=limb_specs(mixamo_prefix)
	for spec in specs:
		if sk.find_bone(spec[0])<0 or sk.find_bone(spec[1])<0:return false
	physics_root=Node3D.new();physics_root.name="DeathPhysics";actor.add_child(physics_root)
	var bodies={}
	var lowest:=INF
	for spec in specs:
		if actor.has_meta("head_off") and str(spec[0]).ends_with("Head"):continue
		if actor.get("_severed")==true and str(spec[0]).begins_with("Left") and "Leg" not in str(spec[0]):continue
		var idx=sk.find_bone(spec[0])
		var bone:Transform3D=sk.global_transform*sk.get_bone_global_pose(idx)
		var end:Vector3=sk.global_transform*sk.get_bone_global_pose(sk.find_bone(spec[1])).origin
		var center=(bone.origin+end)*.5
		var body=RigidBody3D.new();body.name=spec[0]
		body.add_child(preload("res://modules/combat/debris_pause.gd").new())
		body.collision_layer=0;body.collision_mask=1;body.mass=spec[4]
		body.linear_damp=.3;body.angular_damp=1.5
		body.continuous_cd=true
		var pm=PhysicsMaterial.new();pm.friction=.85;pm.bounce=0.0;body.physics_material_override=pm
		physics_root.add_child(body)
		body.global_transform=Transform3D(bone.basis.orthonormalized(),center)
		var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new()
		capsule.radius=spec[3];capsule.height=maxf(capsule.radius*2, bone.origin.distance_to(end)+capsule.radius*.5)
		shape.shape=capsule
		var axis=(body.global_basis.inverse()*(end-bone.origin)).normalized()
		shape.quaternion=Quaternion(Vector3.UP,axis)
		body.add_child(shape)
		bindings.append([idx,body,body.global_transform.affine_inverse()*bone])
		bodies[spec[0]]=body
		if bodies.has(spec[2]):
			var joint=ConeTwistJoint3D.new();physics_root.add_child(joint)
			joint.global_position=bone.origin
			# Cone X axis follows this limb at the handoff pose.
			joint.global_basis=Basis(Quaternion(Vector3.RIGHT,(end-bone.origin).normalized()))
			joint.node_a=joint.get_path_to(bodies[spec[2]])
			joint.node_b=joint.get_path_to(body)
			joint.swing_span=deg_to_rad(spec[5]);joint.twist_span=deg_to_rad(20.0)
		body.linear_velocity=Vector3(impulse.x*.35,clampf(impulse.y,0,2),0)
		body.angular_velocity=Vector3(0,0,-signf(impulse.x)*.65)
		lowest=minf(lowest,minf(bone.origin.y,end.y)-spec[3])
	# Capsules starting inside the floor get depenetrated violently and the body
	# explodes; lift the whole proxy so its lowest capsule rests on the floor.
	var floor_y:=actor.global_position.y+.01
	if lowest<floor_y:physics_root.global_position.y+=floor_y-lowest
	_settle=.4
	return true

# Short settling window: no proxy may leave faster than a real collapse.
const SETTLE_SPEED:=5.0
const SETTLE_SPIN:=10.0
var _settle:=0.0
func _physics_process(delta: float) -> void:
	if _settle<=0.0:return
	_settle-=delta
	for binding in bindings:
		var body:RigidBody3D=binding[1]
		if not is_instance_valid(body):continue
		body.linear_velocity=body.linear_velocity.limit_length(SETTLE_SPEED)
		body.angular_velocity=body.angular_velocity.limit_length(SETTLE_SPIN)

func _process_modification() -> void:
	var sk=get_skeleton()
	for binding in bindings:
		var body:RigidBody3D=binding[1]
		if is_instance_valid(body):
			var pose:Transform3D=sk.global_transform.affine_inverse()*body.global_transform*binding[2]
			sk.set_bone_global_pose(binding[0],pose)
