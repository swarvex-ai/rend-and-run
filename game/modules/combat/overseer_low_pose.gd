extends SkeletonModifier3D
## Low attack arm IK after the shared crouch modifier. Feet and Rend are untouched.
var actor: CharacterBody3D
var amount := 0.0

func _process_modification() -> void:
 if not is_instance_valid(actor):return
 var eligible: bool=actor._committed_low and actor._state in [actor.WINDUP,actor.SWING,actor.RECOVERY] and not actor._hit_recovering and not actor._dead
 var desired := 1.0 if eligible else 0.0
 if eligible and actor._state==actor.RECOVERY:desired=1.0-clampf(actor._state_t/.5,0,1)
 amount=move_toward(amount,desired,get_process_delta_time()*12)
 if amount<.001:return
 var sk:=get_skeleton()
 var upper:=_bone(sk,"mixamorig_RightArm")
 var lower:=_bone(sk,"mixamorig_RightForeArm")
 var hand:=_bone(sk,"mixamorig_RightHand")
 var grip:=sk.find_bone("hand_r")
 if mini(mini(upper,lower),mini(hand,grip))<0:return
 var front:float=actor._attack_front
 var swing:float=clampf(actor._state_t/.2,0,1) if actor._state==actor.SWING else 0.0 if actor._state==actor.WINDUP else 1.0
 var progress:=smoothstep(0.0,1.0,swing)
 # A horizontal arc towards the target, at shin height. Rotate in the XZ plane
 # rather than dropping the entire weapon independently of the animated wrist.
 var angle:=lerpf(-1.05,0.4,progress)
 var blade_y:=Vector3(front*cos(angle),0,sin(angle))
 var blade_x:=Vector3.UP
 var blade_z:=blade_x.cross(blade_y).normalized()
 var world_grip:=Transform3D(Basis(blade_x,blade_y,blade_z),actor.global_position+Vector3(front*lerpf(.15,.48,progress),.43,.12))
 var desired_grip:=sk.global_transform.affine_inverse()*world_grip
 var grip_local:=sk.get_bone_global_pose(hand).affine_inverse()*sk.get_bone_global_pose(grip)
 var target_hand:=desired_grip*grip_local.affine_inverse()
 var original:=sk.get_bone_global_pose(hand)
 target_hand=original.interpolate_with(target_hand,amount)
 var a:=sk.get_bone_global_pose(upper).origin
 var b:=sk.get_bone_global_pose(lower).origin
 var c:=original.origin
 var l1:=a.distance_to(b);var l2:=b.distance_to(c)
 var delta:=target_hand.origin-a
 var distance:=clampf(delta.length(),absf(l1-l2)+.001,l1+l2-.001)
 var axis:=delta.normalized()
 var pole:=sk.global_basis.inverse()*Vector3(0,0,.8)
 pole=(pole-axis*axis.dot(pole)).normalized()
 var along:float=(l1*l1-l2*l2+distance*distance)/(2*distance)
 var bend:=sqrt(maxf(0,l1*l1-along*along))
 _aim(sk,upper,lower,a+axis*along+pole*bend)
 _aim(sk,lower,hand,target_hand.origin)
 var hand_pose:=sk.get_bone_global_pose(hand)
 hand_pose.basis=target_hand.basis
 _set_global(sk,hand,hand_pose)

func _aim(sk: Skeleton3D,bone: int,child: int,target: Vector3) -> void:
 var pose:=sk.get_bone_global_pose(bone)
 var from:=sk.get_bone_global_pose(child).origin-pose.origin
 var to:=target-pose.origin
 if from.length_squared()<.000001 or to.length_squared()<.000001:return
 pose.basis=Basis(Quaternion(from.normalized(),to.normalized()))*pose.basis
 _set_global(sk,bone,pose)

func _set_global(sk: Skeleton3D,bone: int,pose: Transform3D) -> void:
 var parent:=sk.get_bone_parent(bone)
 var local:=sk.get_bone_global_pose(parent).affine_inverse()*pose if parent>=0 else pose
 sk.set_bone_pose_position(bone,local.origin)
 sk.set_bone_pose_rotation(bone,local.basis.orthonormalized().get_rotation_quaternion())

func _bone(sk: Skeleton3D,name: String) -> int:
 var found:=sk.find_bone(name)
 if found>=0:return found
 return sk.find_bone(name.trim_prefix("mixamorig_"))
