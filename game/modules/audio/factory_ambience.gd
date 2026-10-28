extends Node
## Scene-owned room bed. Player position controls the room/rack blend so a
## distant 2.5D camera does not attenuate away the machinery next to Rend.
var actor: Node3D
var ventilation: AudioStreamPlayer
var servers: AudioStreamPlayer

func _ready() -> void:
	ventilation = _loop(preload("res://audio/ambience/factory_ventilation.wav"), "Ventilation")
	servers = _loop(preload("res://audio/ambience/server_fans.wav"), "ServerFans")

func _loop(source: AudioStreamWAV, label: String) -> AudioStreamPlayer:
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	var player := AudioStreamPlayer.new()
	player.name = label
	player.bus = "Ambience"
	player.stream = stream
	player.volume_linear = 0.0
	add_child(player)
	player.play()
	return player

func _process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	var x := actor.global_position.x
	var room := smoothstep(-5.0, -3.0, x) * (1.0 - smoothstep(13.8, 16.5, x))
	var rack := smoothstep(7.0, 11.0, x) * room
	var blend := 1.0 - exp(-3.0 * delta)
	ventilation.volume_linear = lerpf(ventilation.volume_linear, db_to_linear(-8.0) * room * (1.0 - .25 * rack), blend)
	servers.volume_linear = lerpf(servers.volume_linear, db_to_linear(-9.0) * rack, blend)

func _exit_tree() -> void:
	# Retire looping playbacks before the scene is released or reloaded.
	for player in [ventilation, servers]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
