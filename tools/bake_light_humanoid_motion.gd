extends SceneTree
const NAMES={"Spine02":"Spine","Spine01":"Spine1","Spine":"Spine2","neck":"Neck"}
const TIPS={"Hips":"Spine02","Spine02":"Spine01","Spine01":"Spine","Spine":"neck","neck":"Head","LeftShoulder":"LeftArm","LeftArm":"LeftForeArm","LeftForeArm":"LeftHand","RightShoulder":"RightArm","RightArm":"RightForeArm","RightForeArm":"RightHand","LeftUpLeg":"LeftLeg","LeftLeg":"LeftFoot","LeftFoot":"LeftToeBase","RightUpLeg":"RightLeg","RightLeg":"RightFoot","RightFoot":"RightToeBase"}
func _initialize():call_deferred("run")
func run():
	var source=load("res://assets3d/releases/chaser_v01/enemy_chaser.glb").instantiate();root.add_child(source)
	var target=load("res://assets3d/characters/light_humanoid_v1/model.glb").instantiate();root.add_child(target);target.rotation.y=PI/2
	var src=source.find_child("Skeleton3D",true,false)
	var dst=target.find_child("Skeleton3D",true,false)
	var player=source.find_child("AnimationPlayer",true,false)
	player.add_animation_library("combat",load("res://generated/chaser_motion.tres"))
	var library=AnimationLibrary.new()
	var mapping={}
	for i in dst.get_bone_count():
		var name=dst.get_bone_name(i)
		mapping[i]=src.find_bone("mixamorig_"+NAMES.get(name,name))
		assert(mapping[i]>=0,"Missing bone "+name)
	var src_hip=src.find_bone("mixamorig_Hips")
	var ratio=(dst.global_transform*dst.get_bone_global_rest(0)).origin.y/(src.global_transform*src.get_bone_global_rest(src_hip)).origin.y
	for clip in ["idle","slash_light","hit_react"]:
		var original=player.get_animation("combat/"+clip)
		var result=Animation.new();result.length=original.length;result.loop_mode=original.loop_mode
		for i in dst.get_bone_count():
			var track=result.add_track(Animation.TYPE_ROTATION_3D)
			result.track_set_path(track,NodePath("Armature/Skeleton3D:"+dst.get_bone_name(i)))
		var hip_track=result.add_track(Animation.TYPE_POSITION_3D)
		result.track_set_path(hip_track,NodePath("Armature/Skeleton3D:Hips"))
		player.play("combat/"+clip);player.advance(0);player.pause()
		for frame in range(int(ceil(original.length*30))+1):
			var time=minf(frame/30.0,original.length)
			src.reset_bone_poses();player.seek(time,true);player.advance(0)
			dst.reset_bone_poses()
			for i in dst.get_bone_count():
				var si=mapping[i]
				var posed=src.global_transform*src.get_bone_global_pose(si)
				var resting=src.global_transform*src.get_bone_global_rest(si)
				var target_rest=dst.global_transform*dst.get_bone_global_rest(i)
				var desired=posed.basis.orthonormalized()*resting.basis.orthonormalized().inverse()*target_rest.basis.orthonormalized()
				var name=dst.get_bone_name(i)
				if TIPS.has(name):
					var child=dst.find_bone(TIPS[name]);var source_child=mapping[child]
					var direction=(src.global_transform*src.get_bone_global_pose(source_child)).origin-posed.origin
					var local_direction=dst.get_bone_rest(child).origin
					var current=desired*local_direction
					if direction.length()>.0001 and current.length()>.0001:desired=Basis(Quaternion(current.normalized(),direction.normalized()))*desired
				var parent=dst.get_bone_parent(i)
				var parent_basis=dst.global_basis.orthonormalized() if parent<0 else (dst.global_basis*dst.get_bone_global_pose(parent).basis).orthonormalized()
				var rotation=(parent_basis.inverse()*desired).orthonormalized().get_rotation_quaternion()
				dst.set_bone_pose_rotation(i,rotation)
				result.rotation_track_insert_key(i,time,rotation)
			var delta=(src.global_transform*src.get_bone_global_pose(src_hip)).origin-(src.global_transform*src.get_bone_global_rest(src_hip)).origin
			var position=dst.get_bone_rest(0).origin+dst.global_basis.inverse()*delta*ratio
			result.position_track_insert_key(hip_track,time,position)
		library.add_animation(clip,result)
	# Reuse the already-paid provider locomotion on its unchanged target skeleton.
	for item in [["walk","anim_walking_skeletonclip.glb"],["run","anim_running_skeletonclip.glb"]]:
		var document=GLTFDocument.new();var state=GLTFState.new()
		assert(document.append_from_file(OS.get_environment("RIG_SOURCE")+"/"+item[1],state)==OK)
		var clip_scene=document.generate_scene(state)
		var clip_player=clip_scene.find_child("AnimationPlayer",true,false)
		var animation=clip_player.get_animation(clip_player.get_animation_list()[0]).duplicate(true)
		animation.loop_mode=Animation.LOOP_LINEAR
		library.add_animation(item[0],animation)
		clip_scene.free()
	assert(ResourceSaver.save(library,OS.get_environment("RETARGET_OUTPUT")+"/light_combat.tres")==OK)
	source.free();target.free();quit()
