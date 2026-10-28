extends SceneTree
## Retarget clips from a Meshy animation GLB onto a game character and save them
## as an AnimationLibrary. World-space pose deltas (posed vs. rest) are applied to
## the target's rest, so differing bone rolls between rigs do not distort limbs.
##
## godot --headless --path game -s res://../tools/retarget_clips.gd  (run via tools/retarget_clips.sh)
## Environment:
##   SOURCE_GLB   absolute path of the Meshy animation GLB (Meshy bone names)
##   TARGET       res:// path of the game character scene/GLB
##   TARGET_YAW   radians applied to the target root so both face the same way (default 0)
##   BONE_PREFIX  prefix of target bone names, e.g. "mixamorig_" for Rend ("" for Meshy rigs)
##   CLIPS        comma list "SourceName=target_name" (source names as in the GLB)
##   LOOPS        comma list of target clip names that loop
##   OUTPUT       absolute path of the .tres library to write
##   SKELETON_PATH  track path prefix inside the target (default "Armature/Skeleton3D")
##   INPLACE      "1" keeps only the vertical hip motion, so gameplay code owns travel;
##                the removed horizontal travel is stored per clip as metadata
##                "root_motion" (PackedVector3Array, skeleton-local, one entry per 1/30 s)
##   WARP         "target_name=top,impact,end;..." retimes an attack so source times
##                top/impact/end land on the game's 0.30/0.55/0.85 s attack grid
const MIXAMO := {"Spine02":"Spine","Spine01":"Spine1","Spine":"Spine2","neck":"Neck"}
const FPS := 30.0

func _initialize():call_deferred("run")

func _load_gltf(path: String) -> Node:
	var document := GLTFDocument.new();var state := GLTFState.new()
	assert(document.append_from_file(path,state)==OK,"cannot read "+path)
	return document.generate_scene(state)

func run():
	var source := _load_gltf(OS.get_environment("SOURCE_GLB"));root.add_child(source)
	var target_path := OS.get_environment("TARGET")
	var target: Node3D = load(target_path).instantiate();root.add_child(target)
	target.rotation.y=float(OS.get_environment("TARGET_YAW")) if OS.has_environment("TARGET_YAW") else 0.0
	var prefix := OS.get_environment("BONE_PREFIX")
	var skeleton_path := OS.get_environment("SKELETON_PATH") if OS.has_environment("SKELETON_PATH") else "Armature/Skeleton3D"
	var src: Skeleton3D = source.find_child("Skeleton3D",true,false)
	var dst: Skeleton3D = target.find_child("Skeleton3D",true,false)
	var player: AnimationPlayer = source.find_child("AnimationPlayer",true,false)
	# Target bone -> source bone (Meshy naming); unmapped target bones keep their rest.
	var mapping := {}
	for si in src.get_bone_count():
		var name := src.get_bone_name(si)
		var ti := dst.find_bone(prefix+(MIXAMO.get(name,name) if prefix!="" else name))
		if ti>=0:mapping[ti]=si
	print("RETARGET mapped %d of %d target bones" % [mapping.size(),dst.get_bone_count()])
	var src_hip := src.find_bone("Hips");var dst_hip := dst.find_bone(prefix+"Hips")
	var ratio := (dst.global_transform*dst.get_bone_global_rest(dst_hip)).origin.y/(src.global_transform*src.get_bone_global_rest(src_hip)).origin.y
	var order: Array[int]=[]  # parents before children
	for i in dst.get_bone_count():order.append(i)
	order.sort_custom(func(a,b):return _depth(dst,a)<_depth(dst,b))
	var loops := OS.get_environment("LOOPS").split(",",false)
	var library := AnimationLibrary.new()
	for pair in OS.get_environment("CLIPS").split(",",false):
		var names := pair.split("=");var clip_name := names[1]
		var original := player.get_animation(names[0])
		assert(original!=null,"missing clip "+names[0])
		var result := Animation.new();result.length=original.length
		result.loop_mode=Animation.LOOP_LINEAR if clip_name in loops else Animation.LOOP_NONE
		var tracks := {}
		for ti in mapping:
			var track := result.add_track(Animation.TYPE_ROTATION_3D)
			result.track_set_path(track,NodePath(skeleton_path+":"+dst.get_bone_name(ti)));tracks[ti]=track
		var hip_track := result.add_track(Animation.TYPE_POSITION_3D)
		result.track_set_path(hip_track,NodePath(skeleton_path+":"+dst.get_bone_name(dst_hip)))
		player.play(names[0]);player.advance(0);player.pause()
		var root_motion := PackedVector3Array()
		for frame in range(int(ceil(original.length*FPS))+1):
			var time := minf(frame/FPS,original.length)
			src.reset_bone_poses();player.seek(time,true);player.advance(0)
			dst.reset_bone_poses()
			for ti in order:
				if not mapping.has(ti):continue
				var si: int = mapping[ti]
				var posed := src.global_transform*src.get_bone_global_pose(si)
				var resting := src.global_transform*src.get_bone_global_rest(si)
				var target_rest := dst.global_transform*dst.get_bone_global_rest(ti)
				var desired := posed.basis.orthonormalized()*resting.basis.orthonormalized().inverse()*target_rest.basis.orthonormalized()
				var parent := dst.get_bone_parent(ti)
				var parent_basis := dst.global_basis.orthonormalized() if parent<0 else (dst.global_basis*dst.get_bone_global_pose(parent).basis).orthonormalized()
				var rotation := (parent_basis.inverse()*desired).orthonormalized().get_rotation_quaternion()
				dst.set_bone_pose_rotation(ti,rotation)
				result.rotation_track_insert_key(tracks[ti],time,rotation)
			var delta := (src.global_transform*src.get_bone_global_pose(src_hip)).origin-(src.global_transform*src.get_bone_global_rest(src_hip)).origin
			if OS.get_environment("INPLACE")=="1":
				root_motion.append(dst.global_basis.inverse()*Vector3(delta.x,0,delta.z)*ratio)
				delta=Vector3(0,delta.y,0)
			result.position_track_insert_key(hip_track,time,dst.get_bone_rest(dst_hip).origin+dst.global_basis.inverse()*delta*ratio)
		var warps := {}
		for spec in OS.get_environment("WARP").split(";",false):
			var parts := spec.split("=");warps[parts[0]]=Array(parts[1].split(",")).map(func(v):return float(v))
		if warps.has(clip_name):_warp(result,warps[clip_name])
		elif not root_motion.is_empty():result.set_meta("root_motion",root_motion)
		library.add_animation(clip_name,result)
		print("RETARGET %s -> %s %.2fs" % [names[0],clip_name,original.length])
	assert(ResourceSaver.save(library,OS.get_environment("OUTPUT"))==OK)
	source.free();target.free();quit()

# Piecewise-linear retime: [0,top]->[0,.30], [top,impact]->[.30,.55], [impact,end]->[.55,.85].
func _warp(animation: Animation, marks: Array) -> void:
	var src := [0.0, marks[0], marks[1], marks[2]];var dst := [0.0, 0.30, 0.55, 0.85]
	for track in animation.get_track_count():
		# Read every key first, then rebuild: moving keys in place re-sorts the track
		# under the loop, which scrambles the key order and makes the pose jitter.
		var keys := []
		for key in animation.track_get_key_count(track):
			keys.append([animation.track_get_key_time(track, key), animation.track_get_key_value(track, key)])
		while animation.track_get_key_count(track) > 0:animation.track_remove_key(track, 0)
		for entry in keys:
			var t: float = entry[0]
			if t > src[3]:continue
			var i := 0
			while i < 2 and t > src[i + 1]:i += 1
			var time := lerpf(dst[i], dst[i + 1], (t - src[i]) / maxf(src[i + 1] - src[i], 0.0001))
			if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:animation.rotation_track_insert_key(track, time, entry[1])
			else:animation.position_track_insert_key(track, time, entry[1])
	animation.length = dst[3]

func _depth(skeleton: Skeleton3D, bone: int) -> int:
	var depth := 0
	while skeleton.get_bone_parent(bone)>=0:
		bone=skeleton.get_bone_parent(bone);depth+=1
	return depth
