extends SceneTree
## Contract test for the voice audio route: Rend's voice player and the settings'
## "Voices volume" bus use Voice, while the general FX players keep playing on Combat.
var failures := 0

func check(label: String, ok: bool) -> void:
	print("VOICE_BUS ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	await process_frame
	var fx := root.get_node_or_null("FX")
	check("the FX autoload exists", fx != null)
	if fx == null: quit(1); return
	check("the voice takes are loaded", fx._voices.has("rend_hurt_light"))
	# Trigger the lazy voice player exactly like the game does.
	fx.voice("rend_hurt_light")
	var player: AudioStreamPlayer = fx._voice_player
	check("the voice player is created on first use", player != null)
	if player != null:
		check("the voice player plays on Voice", player.bus == "Voice")
	var voice_index := AudioServer.get_bus_index("Voice")
	check("the Voice bus exists", voice_index >= 0)
	if voice_index >= 0:
		check("the Voice bus sends to Master", AudioServer.get_bus_send(voice_index) == &"Master")
	var all_combat: bool = not fx._players.is_empty()
	for p in fx._players:
		if p.bus != "Combat": all_combat = false
	check("the other FX players stay on Combat", all_combat)
	print("VOICE_BUS SUMMARY failures=", failures)
	quit(1 if failures else 0)
