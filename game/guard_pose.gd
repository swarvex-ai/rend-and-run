extends "res://crouch_pose.gd"
## Two-joint left-arm guard overlay; sword animation remains unmodified.
func _process_modification() -> void:
	if not is_instance_valid(actor) or not actor.shield_unlocked:return
	var sk:=get_skeleton()
	if is_instance_valid(actor.gun):
		# Both hands are on the gun: the shield is slung flat across his back.
		amount=0.0
		var chest:Vector3=sk.to_global(sk.get_bone_global_pose(sk.find_bone("mixamorig_Spine2")).origin)
		var forward:Vector3=(actor.pivot.global_basis.x*Vector3(1,0,1)).normalized()
		if is_instance_valid(actor.shield_visual):
			actor.shield_visual.global_basis=Basis.looking_at(forward,Vector3.UP)  # face (+Z) to the rear
			actor.shield_visual.global_position=chest-forward*0.2-Vector3(0,0.15,0)
		return
	var upper:=sk.find_bone("mixamorig_LeftArm")
	var lower:=sk.find_bone("mixamorig_LeftForeArm")
	var hand:=sk.find_bone("mixamorig_LeftHand")
	if upper<0 or lower<0 or hand<0:return
	amount=move_toward(amount,1.0 if actor.guard.is_guarding() else 0.0,get_process_delta_time()*14)
	if amount>0.001:
		var a:=sk.get_bone_global_pose(upper).origin
		var b:=sk.get_bone_global_pose(lower).origin
		var c:=sk.get_bone_global_pose(hand).origin
		var wanted:=sk.to_local(actor.global_position+Vector3(actor.facing*0.38,0.79 if actor.crouching else 1.12,0.20))
		var goal:=c.lerp(wanted,amount)
		var axis:=(goal-a).normalized()
		var l1:=a.distance_to(b);var l2:=b.distance_to(c)
		var d:=clampf(a.distance_to(goal),absf(l1-l2)+0.001,l1+l2-0.001)
		var side:=sk.global_basis.inverse()*Vector3(0,-0.4,1)
		var pole:=(side-axis*side.dot(axis)).normalized()
		var along:=(l1*l1-l2*l2+d*d)/(2*d)
		var elbow:=a+axis*along+pole*sqrt(maxf(0,l1*l1-along*along))
		_aim(sk,upper,lower,elbow);_aim(sk,lower,hand,goal)
	if is_instance_valid(actor.shield_visual):
		actor.shield_visual.global_basis=Basis(Vector3.UP,actor.facing*lerpf(0.25,0.85,amount))
		actor.shield_visual.global_position=sk.to_global(sk.get_bone_global_pose(hand).origin)+Vector3(0,0.08,0)+actor.shield_visual.global_basis.z*0.10
