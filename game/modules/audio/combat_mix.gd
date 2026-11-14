class_name CombatMix
extends Node
## Combat mix: manages priority-1 audio ducking for Music and Ambience buses.
## Lower Music and Ambience when priority-1 cues (attack tells, warnings) are active.
## Attack: 100 ms (0.1 s). Release: 600 ms (0.6 s) after the last token ends.
## Uses delta in _process. Never touches the Combat bus.
## Remembers each bus's own volume (Options sliders) and restores it.

const ATTACK_TIME := 0.1
const RELEASE_TIME := 0.6

const SETTINGS_STORE = preload("res://modules/persistence/settings_store.gd")

var _next_token: int = 1
var _tokens: Dictionary = {}  # token -> {"music_db": float, "ambience_db": float}

# Ducking state: 0.0 = no ducking, 1.0 = fully ducked
var _duck_progress: float = 0.0

var _target_music_duck: float = 0.0
var _target_ambience_duck: float = 0.0

# Base volumes remembered from before ducking started
var _base_music_db: float = 0.0
var _base_ambience_db: float = 0.0
var _has_base_volumes: bool = false

var _music_bus_idx: int = -1
var _ambience_bus_idx: int = -1

func _ready() -> void:
	_ensure_buses()

func _ensure_buses() -> void:
	_music_bus_idx = SETTINGS_STORE.bus_index("Music")
	_ambience_bus_idx = SETTINGS_STORE.bus_index("Ambience")

func begin_priority1(music_db: float = -8.0, ambience_db: float = -6.0) -> int:
	_ensure_buses()
	if _tokens.is_empty() and _duck_progress <= 0.0:
		_base_music_db = AudioServer.get_bus_volume_db(_music_bus_idx)
		_base_ambience_db = AudioServer.get_bus_volume_db(_ambience_bus_idx)
		_has_base_volumes = true

	var token := _next_token
	_next_token += 1
	# Store the requested dB (negative floats, e.g. -8.0 dB means lower by 8 dB)
	# Largest reduction means largest magnitude (most negative, e.g. minf)
	_tokens[token] = {
		"music_db": music_db,
		"ambience_db": ambience_db
	}
	_update_targets()
	return token

func end_priority1(token: int) -> void:
	if _tokens.has(token):
		_tokens.erase(token)
		_update_targets()

func _update_targets() -> void:
	if _tokens.is_empty():
		return
	var max_music_drop := 0.0
	var max_amb_drop := 0.0
	for t in _tokens.values():
		var m_drop: float = absf(t["music_db"])
		var a_drop: float = absf(t["ambience_db"])
		if m_drop > max_music_drop:
			max_music_drop = m_drop
		if a_drop > max_amb_drop:
			max_amb_drop = a_drop
	_target_music_duck = -max_music_drop
	_target_ambience_duck = -max_amb_drop

func _process(delta: float) -> void:
	_ensure_buses()
	if not _tokens.is_empty():
		# Attack phase: ramp _duck_progress towards 1.0 over ATTACK_TIME
		if _duck_progress < 1.0:
			_duck_progress = minf(1.0, _duck_progress + delta / ATTACK_TIME)
		var current_music_vol := _base_music_db + _target_music_duck * _duck_progress
		var current_amb_vol := _base_ambience_db + _target_ambience_duck * _duck_progress
		AudioServer.set_bus_volume_db(_music_bus_idx, current_music_vol)
		AudioServer.set_bus_volume_db(_ambience_bus_idx, current_amb_vol)
	elif _duck_progress > 0.0:
		# Release phase: ramp _duck_progress towards 0.0 over RELEASE_TIME
		_duck_progress = maxf(0.0, _duck_progress - delta / RELEASE_TIME)
		var current_music_vol := _base_music_db + _target_music_duck * _duck_progress
		var current_amb_vol := _base_ambience_db + _target_ambience_duck * _duck_progress
		AudioServer.set_bus_volume_db(_music_bus_idx, current_music_vol)
		AudioServer.set_bus_volume_db(_ambience_bus_idx, current_amb_vol)
		if _duck_progress <= 0.0:
			_has_base_volumes = false
