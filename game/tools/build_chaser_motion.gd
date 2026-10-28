extends SceneTree
func _initialize() -> void:
	call_deferred("build")
func build() -> void:
	var src: Node3D=load("res://assets3d/releases/hero_v05/characters/hero_rendrun.glb").instantiate()
	var dst: Node3D=load("res://assets3d/releases/chaser_v01/enemy_chaser.glb").instantiate()
	root.add_child(src);root.add_child(dst)
	var ss: Skeleton3D=src.find_child("Skeleton3D",true,false)
	var ds: Skeleton3D=dst.find_child("Skeleton3D",true,false)
	var sa: AnimationPlayer=src.find_child("AnimationPlayer",true,false)
	var da: AnimationPlayer=dst.find_child("AnimationPlayer",true,false)
	print("SOCKET ",ss.get_bone_global_rest(ss.find_bone("mixamorig_RightHand")).affine_inverse()*ss.get_bone_global_rest(ss.find_bone("hand_r")))
	print("PATH ",da.get_node(da.root_node).get_path_to(ds))
	var grip:=ds.add_bone("hand_r")
	ds.set_bone_parent(grip,ds.find_bone("mixamorig_RightHand"))
	var grip_rest:=ss.get_bone_rest(ss.find_bone("hand_r"));grip_rest.origin*=0.5
	ds.set_bone_rest(grip,grip_rest)
	var library:=AnimationLibrary.new()
	for clip in ["idle","slash_light","slash_combo_2","hit_react"]:
		var source:=sa.get_animation(clip)
		var anim:=Animation.new()
		anim.length=source.length
		anim.loop_mode=Animation.LOOP_LINEAR if clip=="idle" else Animation.LOOP_NONE
		var mapped:=0
		for t in source.get_track_count():
			var path:=source.track_get_path(t)
			if path.get_subname_count()==0: continue
			var bone:=str(path.get_subname(0))
			var si:=ss.find_bone(bone);var di:=ds.find_bone(bone)
			if si<0 or di<0:continue
			var type:=source.track_get_type(t)
			if type!=Animation.TYPE_ROTATION_3D and not(type==Animation.TYPE_POSITION_3D and bone=="mixamorig_Hips"):continue
			var track:=anim.add_track(type)
			anim.track_set_path(track,NodePath(str(da.get_node(da.root_node).get_path_to(ds))+":"+bone))
			var sr:=ss.get_bone_rest(si);var dr:=ds.get_bone_rest(di)
			for k in source.track_get_key_count(t):
				var value=source.track_get_key_value(t,k)
				if type==Animation.TYPE_ROTATION_3D:
					value=value # Both delivered rigs share Mixamo local joint axes; retain authored orientation.
				else:
					value=dr.origin+(value-sr.origin)*0.50
				anim.track_insert_key(track,source.track_get_key_time(t,k),value)
			mapped+=1
		library.add_animation(clip,anim)
		print(clip," tracks=",mapped," length=",anim.length)
	ResourceSaver.save(library,"res://generated/chaser_motion.tres")
	src.free();dst.free();quit()
