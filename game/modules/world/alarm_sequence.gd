extends Node3D
## Escape alarm for the opening: Rend breaks out of the first room, the plant knows at once.
## Red beacons spin, a siren wails and the first guard storms in as soon as he has the arm,
## so the game opens with pressure instead of a walk. Fades out once the first fight is won
## (or after a while if he lingers). Owned by lab_route.

const BEACON_XS := [-1.0, 5.5, 11.5]
const MAX_TIME := 45.0

var running := false
var _beacons: Array = []
var _siren: AudioStreamPlayer
var _t := 0.0

func start() -> void:
	running = true;_t = 0.0
	for x in BEACON_XS:
		var beacon := preload("res://modules/visuals/alarm_beacon.gd").new()
		beacon.name = "EscapeAlarmBeacon";beacon.position = Vector3(x, 3.45, -1.5);beacon.forced = true
		add_child(beacon);_beacons.append(beacon)
	_siren = AudioStreamPlayer.new();_siren.name = "Siren"
	var stream := (load("res://audio/alarm_siren.wav") as AudioStreamWAV).duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD;stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	_siren.stream = stream;_siren.volume_db = -15.0;_siren.bus = "Ambience" if AudioServer.get_bus_index("Ambience") >= 0 else "Master"
	add_child(_siren);_siren.play()

func stop() -> void:
	if not running:return
	running = false
	for beacon in _beacons:if is_instance_valid(beacon):beacon.forced = false
	if is_instance_valid(_siren):
		var tw := create_tween();tw.tween_property(_siren, "volume_db", -60.0, 2.5);tw.tween_callback(_siren.stop)

func _process(delta: float) -> void:
	if not running:return
	_t += delta
	if _t > MAX_TIME:stop()

func _exit_tree() -> void:
	if is_instance_valid(_siren):_siren.stop();_siren.stream = null
