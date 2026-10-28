extends Node
## Failing fluorescent fixture: mostly lit, with irregular stutters and short dropouts.
## Drives the energy of its lights and the emission of its diffuser material together.
var lights: Array[Light3D] = []
var diffuser: StandardMaterial3D
var _base: Array[float] = []
var _base_emission := 1.0
var _wait := 0.0
var _burst := 0

func _ready() -> void:
	for light in lights:_base.append(light.light_energy)
	if diffuser:_base_emission = diffuser.emission_energy_multiplier
	_wait = randf_range(0.5, 3.0)

func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:return
	var level := 1.0
	if _burst > 0:
		# A stutter: a few fast on/off frames at reduced level.
		_burst -= 1
		level = 0.08 if _burst % 2 == 0 else randf_range(0.45, 0.8)
		_wait = randf_range(0.03, 0.09)
	else:
		_burst = 2 * randi_range(1, 4)
		_wait = randf_range(1.2, 5.5)
	_apply(level)

func _apply(level: float) -> void:
	for i in lights.size():
		if is_instance_valid(lights[i]):lights[i].light_energy = _base[i] * level
	if diffuser:diffuser.emission_energy_multiplier = _base_emission * level
