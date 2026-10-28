extends SkeletonModifier3D
## Upper-body hit reaction, the usual action-game setup: a mocap reaction clip is layered
## additively onto spine, neck, head and arms only, so whatever the legs are doing
## (standing, walking) keeps the feet planted. Additive means only the clip's motion away
## from its own first frame is added, so Rend keeps his stance and weapon grip.
## Short and crisp: the clip runs to its strongest pose, holds a beat, then fades out.

## Mixamo names (Rend, after PREFIX) and Meshy names (robots: Spine02/Spine01/neck).
const UPPER := ["Spine", "Spine1", "Spine2", "Spine01", "Spine02", "Neck", "neck", "Head",
	"LeftShoulder", "LeftArm", "LeftForeArm", "RightShoulder", "RightArm", "RightForeArm"]
const PREFIX := "mixamorig_"
var arm_weight := 0.5     # arms follow the clip only halfway: the weapon stays in hand

var _clip: Animation
var _tracks := []         # [bone index, track index, first-frame rotation]
var _t := 0.0
var _end := 0.0           # clip time where the reaction has faded out
var _fade := 0.25
var _weight := 1.0
var _marks := {}          # clip -> [onset, peak] (cached)

## Plays `clip` from its contact; `weight` scales the reaction (above 1 exaggerates it).
func play(clip: Animation, weight := 1.0, hold := 0.08, fade := 0.25) -> void:
	var sk := get_skeleton()
	if clip == null or sk == null:return
	_clip = clip;_t = 0.0;_weight = weight;_fade = fade
	_tracks.clear()
	for track in clip.get_track_count():
		if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D:continue
		var bone_name := str(clip.track_get_path(track)).get_slice(":", 1)
		if not bone_name.trim_prefix(PREFIX) in UPPER:continue
		var bone := sk.find_bone(bone_name)
		if bone >= 0:_tracks.append([bone, track, clip.rotation_track_interpolate(track, 0.0), 1.0 if bone_name.contains("Spine") or bone_name.to_lower().ends_with("neck") or bone_name.ends_with("Head") else arm_weight])
	if not _marks.has(clip):_marks[clip] = _find_marks(clip)
	# Mocap clips idle a moment before the blow lands. Start halfway into the impact so the
	# hit pose already shows during hitstop, as in Dead Cells.
	var onset: float = _marks[clip][0];var peak: float = _marks[clip][1]
	_t = lerpf(onset, peak, 0.5)
	_end = minf(clip.length, peak + hold + fade)

func is_playing() -> bool:
	return _clip != null and _t < _end

# Peak: strongest pose within the first second (largest summed deviation from the first
# frame). Onset: shortly before the deviation first reaches a fifth of that.
func _find_marks(clip: Animation) -> Array:
	var samples := []
	var t := 0.0
	while t < minf(clip.length, 1.2):
		var sum := 0.0
		for entry in _tracks:
			sum += (entry[2] as Quaternion).angle_to(clip.rotation_track_interpolate(entry[1], t))
		samples.append([t, sum]);t += 1.0 / 60.0
	var peak: Array = samples.reduce(func(a, b): return b if b[1] > a[1] else a, samples[0])
	var onset := 0.0
	for sample in samples:
		if sample[1] >= peak[1] * 0.2:onset = maxf(0.0, sample[0] - 0.03);break
	# Keep it crisp: a slow clip's peak is cut to 0.35 s after the onset.
	return [onset, minf(peak[0], onset + 0.35)]

func _process_modification() -> void:
	if not is_playing():return
	_t += get_process_delta_time()
	var w := _weight * clampf((_end - _t) / maxf(_fade, 0.01), 0.0, 1.0)
	if w <= 0.0:return
	var sk := get_skeleton()
	for entry in _tracks:
		var delta: Quaternion = (entry[2] as Quaternion).inverse() * _clip.rotation_track_interpolate(entry[1], minf(_t, _clip.length))
		var bone: int = entry[0]
		delta = delta.normalized()
		var axis := Vector3(delta.x, delta.y, delta.z)
		if axis.length() < 0.0001:continue
		var angle := delta.get_angle()
		var scaled := Quaternion(axis.normalized(), clampf(angle * w * entry[3], -2.2, 2.2))  # weight may exceed 1
		sk.set_bone_pose_rotation(bone, sk.get_bone_pose_rotation(bone) * scaled)
