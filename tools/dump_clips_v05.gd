extends SceneTree
## [P04] Kontakt-Zyt im Clip: FK-Kette Hips..RightHand mit interpolierten Traeckes
## (Positions-Track an Hips ersetzt, Rotations-Track ersetzt Rest-Rotation).
## front = +X laut P03-QA-Report; Peak hand_r.x = Kontakt-Naeherung.
func _init() -> void:
	var h: Node = load("res://assets3d/releases/hero_v05/characters/hero_rendrun.glb").instantiate()
	var sk: Skeleton3D = h.find_child("Skeleton3D", true, false)
	var ap: AnimationPlayer = h.find_child("AnimationPlayer", true, false)
	var chain: Array[String] = ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2", "mixamorig_RightShoulder", "mixamorig_RightArm", "mixamorig_RightForeArm", "mixamorig_RightHand"]
	var idle_ref := 0.0
	for clip in ["idle", "slash_light", "slash_combo_2", "slash_heavy"]:
		var a := ap.get_animation(clip)
		var rest: Array[Transform3D] = []
		for b in chain:
			rest.append(sk.get_bone_rest(sk.find_bone(b)))
		var samples: Array = []
		var t := 0.0
		while t <= a.length + 1e-4:
			var xform := Transform3D.IDENTITY
			for k in range(chain.size()):
				var r := rest[k]
				var rot: Variant = _interp(a, chain[k], t, 2)   # TYPE_3D_ROTATION
				if rot != null:
					r.basis = Basis(rot as Quaternion)
				if k == 0:
					var pos: Variant = _interp(a, chain[k], t, 1)  # TYPE_3D_POSITION
					if pos != null:
						r.origin = pos as Vector3
				xform = xform * r if k > 0 else r
			samples.append([t, xform.origin.x])
			t += 1.0 / 120.0
		if clip == "idle":
			idle_ref = samples[0][1]
		var best := -990.0; var best_t := 0.0
		for s in samples:
			if s[1] > best:
				best = s[1]; best_t = s[0]
		print("%s len=%.3f start_x=%.3f peak_x=%.3f at=%.3f rel=%.0f%% idle_x=%.3f" % [clip, a.length, samples[0][1], best, best_t, 100.0 * best_t / a.length, idle_ref])
	quit()

func _interp(a: Animation, bone: String, t: float, wtype: int):
	for i in a.get_track_count():
		if not String(a.track_get_path(i)).ends_with(bone):
			continue
		if a.track_get_type(i) != wtype:
			continue
		var kk := a.track_get_key_count(i)
		if kk == 0:
			return null
		var idx := 0
		for k in kk:
			if a.track_get_key_time(i, k) <= t + 1e-6:
				idx = k
			else:
				break
		var kt := a.track_get_key_time(i, idx)
		if idx + 1 < kk:
			var kt2: float = a.track_get_key_time(i, idx + 1)
			var f := clampf((t - kt) / maxf(kt2 - kt, 1e-6), 0.0, 1.0)
			if wtype == 2:
				return (a.track_get_key_value(i, idx) as Quaternion).slerp(a.track_get_key_value(i, idx + 1), f)
			return (a.track_get_key_value(i, idx) as Vector3).lerp(a.track_get_key_value(i, idx + 1), f)
		return a.track_get_key_value(i, idx)
	return null
