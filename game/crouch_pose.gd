extends SkeletonModifier3D
## Layered crouch with two-bone leg IK and distance-driven hero steps.
## Attacks/collapse retain authored foot goals; knee poles follow actor forward.
var actor: CharacterBody3D
var amount := 0.0
var collapse := false
var combat_stance := false
var max_foot_error := 0.0
# Distance-driven hero gait: one complete left/right cycle per 1.05 metres.
const CROUCH_CYCLE_DISTANCE := 1.05
var gait_phase := 0.0
var _last_actor_x := 0.0
var _has_position := false
var _gait_weight := 0.0
var _move_weight := 0.0
var _neutral_feet: Dictionary = {}

func _process_modification() -> void:
	if not is_instance_valid(actor): return
	var travelled := absf(actor.global_position.x-_last_actor_x) if _has_position else 0.0
	_last_actor_x=actor.global_position.x;_has_position=true
	var hero_gait := combat_stance and not collapse
	var gait_active: bool = hero_gait and actor.crouching and actor._attack_phase==0 and actor.is_on_floor()
	_move_weight=move_toward(_move_weight,clampf(absf(actor.velocity.x)/.3,0.0,1.0) if gait_active else 0.0,get_process_delta_time()*10.0)
	_gait_weight=move_toward(_gait_weight,1.0 if gait_active else 0.0,get_process_delta_time()*12.0)
	if gait_active and travelled<.5:gait_phase=fposmod(gait_phase+travelled/CROUCH_CYCLE_DISTANCE,1.0)
	var sk := get_skeleton()
	if hero_gait and _neutral_feet.is_empty():
		for side in ["Left","Right"]:
			var bone:=_bone(sk,"mixamorig_"+side+"Foot")
			if bone>=0:_neutral_feet[side]=sk.get_bone_global_rest(bone)
	amount = move_toward(amount, 1.0 if actor.crouching else 0.0, get_process_delta_time()*(3.2 if collapse else 10.0))
	if amount <= 0.001: return
	var hip := _bone(sk,"mixamorig_Hips")
	if hip < 0: return
	var goals: Array = []
	for side in ["Left", "Right"]:
		var upper := _bone(sk,"mixamorig_"+side+"UpLeg")
		var lower := _bone(sk,"mixamorig_"+side+"Leg")
		var foot := _bone(sk,"mixamorig_"+side+"Foot")
		if upper < 0 or lower < 0 or foot < 0: continue
		var a := sk.get_bone_global_pose(upper).origin
		var b := sk.get_bone_global_pose(lower).origin
		var f := sk.get_bone_global_pose(foot)
		# Keep the added stance compact; a wide split drives the rear knee into the floor.
		if combat_stance and not collapse:
			var forward_offset:=Vector3(actor.facing,0,0)*(0.04 if side=="Left" else -0.04)
			f.origin+=sk.global_basis.inverse()*forward_offset*amount*(0.35 if absf(actor.velocity.x)>.3 else 1.0)
		if hero_gait and _gait_weight>0.001:
			var neutral:Transform3D=_neutral_feet[side]
			var neutral_world:=sk.global_transform*neutral
			var phase:=fposmod(gait_phase+(0.0 if side=="Left" else .5),1.0)
			var moving:=_move_weight
			var along:=.315-1.05*phase if phase<.6 else lerpf(-.315,.315,smoothstep(0.0,1.0,(phase-.6)/.4))
			var lift:=0.10*sin(PI*(phase-.6)/.4) if phase>=.6 else 0.0
			var target_world:=Transform3D(neutral_world.basis,Vector3(actor.global_position.x+actor.facing*lerpf(0.0,along,moving),actor.global_position.y+.135+lift*moving,neutral_world.origin.z))
			f=f.interpolate_with(sk.global_transform.affine_inverse()*target_world,_gait_weight*amount)
		goals.append([upper,lower,foot,f,a.distance_to(b),b.distance_to(sk.get_bone_global_pose(foot).origin)])
	var up := sk.global_basis.inverse()*Vector3.UP
	var forward := (sk.global_basis.inverse()*Vector3(actor.facing,0,0)).normalized()
	# Shift hero weight back rather than raising the crouch into low ceilings.
	var pelvis := sk.get_bone_global_pose(hip)
	pelvis.origin += (-up*(0.62 if collapse else 0.40)-forward*(0.22 if combat_stance and not collapse else 0.10))*amount
	if hero_gait and _gait_weight>0.001:
		var hip_rest:=sk.get_bone_global_rest(hip)
		var resting:=hip_rest.origin
		# Foot IK replaces the standing stride: remove its pelvis roll as well,
		# otherwise one hip/knee stays low while the other leg does the squat.
		pelvis.basis=Basis(pelvis.basis.get_rotation_quaternion().slerp(hip_rest.basis.get_rotation_quaternion(),_gait_weight*amount))
		var target_hip:=resting-up*.40-forward*.08
		target_hip+=up*(.012*cos(gait_phase*TAU*2.0))*clampf(absf(actor.velocity.x),0.0,1.0)
		pelvis.origin=pelvis.origin.lerp(target_hip,_gait_weight*amount)
	_set_global(sk,hip,pelvis)
	if collapse or combat_stance:
		var spine := _bone(sk,"mixamorig_Spine")
		if spine >= 0:
			var torso := sk.get_bone_global_pose(spine)
			torso.basis=Basis(Quaternion(up.normalized().cross(forward).normalized(),amount*(1.05 if collapse else lerpf(.38,.58,_gait_weight))))*torso.basis
			_set_global(sk,spine,torso)
	max_foot_error=0.0
	for goal in goals:
		var upper: int=goal[0]; var lower: int=goal[1]; var foot: int=goal[2]
		var target: Transform3D=goal[3]
		var root := sk.get_bone_global_pose(upper).origin
		var delta := target.origin-root
		var l1: float=goal[4]; var l2: float=goal[5]
		var d := clampf(delta.length(),absf(l1-l2)+0.001,l1+l2-0.001)
		var axis := delta.normalized()
		var pole := (forward-axis*forward.dot(axis)).normalized()
		var along := (l1*l1-l2*l2+d*d)/(2*d)
		var bend := sqrt(maxf(0.0,l1*l1-along*along))
		var knee := root+axis*along+pole*bend
		_aim(sk,upper,lower,knee)
		_aim(sk,lower,foot,target.origin)
		var ankle := sk.get_bone_global_pose(foot)
		max_foot_error=maxf(max_foot_error,ankle.origin.distance_to(target.origin))
		ankle.basis=target.basis
		_set_global(sk,foot,ankle)

func _aim(sk: Skeleton3D, bone: int, child: int, target: Vector3) -> void:
	var pose := sk.get_bone_global_pose(bone)
	var current := sk.get_bone_global_pose(child).origin-pose.origin
	var desired := target-pose.origin
	if current.length_squared()<0.000001 or desired.length_squared()<0.000001: return
	pose.basis=Basis(Quaternion(current.normalized(),desired.normalized()))*pose.basis
	_set_global(sk,bone,pose)

func _set_global(sk: Skeleton3D,bone: int,pose: Transform3D) -> void:
	var parent := sk.get_bone_parent(bone)
	var local := sk.get_bone_global_pose(parent).affine_inverse()*pose if parent>=0 else pose
	sk.set_bone_pose_position(bone,local.origin)
	sk.set_bone_pose_rotation(bone,local.basis.orthonormalized().get_rotation_quaternion())

func _bone(sk: Skeleton3D, name: String) -> int:
	var found := sk.find_bone(name)
	if found>=0:return found
	var short_name := name.trim_prefix("mixamorig_")
	if short_name=="Spine":short_name="Spine02"
	return sk.find_bone(short_name)
