extends SceneTree
## Contract test for the alarm beacon (modules/visuals/alarm_beacon.gd): the brief
## caps the alarm light at 3 flashes per second for photosensitivity (G16). It checks
## the rate derived from the spin and light count, measures the actual sweep rate over
## 3 s of game time, and verifies the light turns off and the rotor stops when idle.
const ALARM = preload("res://modules/visuals/alarm_beacon.gd")
const SAMPLE_SECONDS := 3.0
const FPS := 60.0

var failures := 0

func check(label: String, ok: bool, detail := "") -> void:
	print("ALARM ", "PASS " if ok else "FAIL ", label, " ", detail)
	if not ok:
		failures += 1

## Horizontal angle of a spot light's beam (-Z in its local frame), 0 pointing at +Z.
func beam_angle(spot: SpotLight3D) -> float:
	var dir: Vector3 = -spot.global_transform.basis.z
	return atan2(dir.x, dir.z)

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return
	var beacon = ALARM.new()
	root.add_child(beacon)
	beacon.forced = true

	var computed: float = beacon.SPIN / TAU * beacon._lights.size()
	check("computed flash rate is at most 3 Hz", computed <= 3.0, "%.3f Hz" % computed)

	# Let the light reach full level (move_toward at 2.5/s needs 0.4 s).
	var warm := 0
	while beacon._lights[0].light_energy < 14.0 * 0.999 and warm < 120:
		await physics_frame
		warm += 1
	check("the light reaches full level before measuring", beacon._lights[0].light_energy >= 14.0 * 0.999)

	# Unwrapped horizontal phase per light; each crossing of a multiple of TAU is one
	# sweep past the fixed +Z viewing direction.
	var count: int = beacon._lights.size()
	var prev: Array[float] = []
	var phase: Array[float] = []
	for i in count:
		var a := beam_angle(beacon._lights[i])
		prev.append(a)
		phase.append(a)
	var crossings := 0
	for f in int(SAMPLE_SECONDS * FPS):
		await physics_frame
		for i in count:
			var a := beam_angle(beacon._lights[i])
			var was: float = phase[i]
			phase[i] = was + wrapf(a - prev[i], -PI, PI)
			prev[i] = a
			crossings += int(absf(floor(phase[i] / TAU) - floor(was / TAU)))
	var measured := float(crossings) / SAMPLE_SECONDS
	print("ALARM RATES computed=%.3f Hz measured=%.3f Hz crossings=%d" % [computed, measured, crossings])
	check("measured flash rate is at most 3 Hz", measured <= 3.0, "%.3f Hz" % measured)
	check("measured rate is within 0.3 Hz of the computed rate", absf(measured - computed) <= 0.3, "diff=%.3f" % absf(measured - computed))

	# Idle: no robots nearby and not forced, so the light must fade out and stop.
	beacon.forced = false
	var idle := 0
	while beacon._lights[0].light_energy > 0.0 and idle < 60:
		await physics_frame
		idle += 1
	check("the light falls to 0 within 1 s when idle", beacon._lights[0].light_energy == 0.0 and beacon._lens.emission_energy_multiplier == 0.0, "after %.2f s" % (idle / FPS))
	var before: float = beacon._rotor.rotation.y
	for i in 10:
		await physics_frame
	var turned := absf(beacon._rotor.rotation.y - before)
	check("the rotor stops turning when the light is off", turned < 0.0001, "delta=%.5f" % turned)

	print("ALARM SUMMARY failures=", failures)
	beacon.queue_free()
	for i in 3:
		await process_frame
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")
