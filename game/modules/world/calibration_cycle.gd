extends SkeletonModifier3D
## Slow unloaded actuator inspection in a sealed calibration bay.
## Uses the accepted rig in place; no combat, physics or shared-resource edits.
var phase_offset := 0.0
var _elapsed := 0.0
var _arms: Array = []
var _head := -1

func _ready() -> void:
	var sk=get_skeleton()
	for side in ["Left","Right"]:
		var chain=[sk.find_bone(side+"Arm"),sk.find_bone(side+"ForeArm"),sk.find_bone(side+"Hand"),1.0 if side=="Left" else -1.0]
		if chain[0]>=0 and chain[1]>=0 and chain[2]>=0:_arms.append(chain)
	_head=sk.find_bone("Head")

func _process(delta: float) -> void:
	_elapsed+=delta

func _process_modification() -> void:
	var sk=get_skeleton()
	var inverse=sk.global_basis.inverse()
	for arm in _arms:
		# Each side has a different inspection phase. Raised arms stay below 30
		# degrees from vertical, avoiding the imported reference T-pose.
		var t=(_elapsed+phase_offset+(3.0 if arm[3]<0 else 0.0))/16.0
		var test=pow(maxf(0.0,sin(t*TAU)),4.0)
		var upper=Vector3(arm[3]*lerpf(.20,.55,test),-1,.08).normalized()
		var lower=Vector3(arm[3]*.08,-1,.10+.10*test).normalized()
		_aim(sk,arm[0],arm[1],inverse*upper)
		_aim(sk,arm[1],arm[2],inverse*lower)
	if _head>=0:
		var head=sk.get_bone_global_pose(_head)
		var yaw=deg_to_rad(7.0)*sin((_elapsed+phase_offset)*TAU/23.0)
		head.basis=Basis(Quaternion((inverse*Vector3.UP).normalized(),yaw))*head.basis
		sk.set_bone_global_pose(_head,head)

func _aim(sk: Skeleton3D, bone: int, child: int, direction: Vector3) -> void:
	var pose=sk.get_bone_global_pose(bone)
	var current=sk.get_bone_global_pose(child).origin-pose.origin
	if current.length_squared()<.000001:return
	pose.basis=Basis(Quaternion(current.normalized(),direction.normalized()))*pose.basis
	sk.set_bone_global_pose(bone,pose)
