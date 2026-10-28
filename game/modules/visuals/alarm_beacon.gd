extends Node3D
## Ceiling alarm beacon: a rotating red light that runs while robots nearby hunt Rend.
const RADIUS := 11.0
const SPIN := 5.5  # rad/s
var active := false
var forced := false  # the escape alarm keeps it running regardless of nearby robots
var _rotor: Node3D
var _lens: StandardMaterial3D
var _lights: Array[SpotLight3D] = []

func _ready() -> void:
	var housing := MeshInstance3D.new();var base := CylinderMesh.new()
	base.top_radius = .11;base.bottom_radius = .13;base.height = .07;housing.mesh = base
	var dark := StandardMaterial3D.new();dark.albedo_color = Color(.05, .06, .07);dark.metallic = .6;dark.roughness = .4
	housing.material_override = dark;housing.position.y = .035;add_child(housing)
	var dome := MeshInstance3D.new();var cap := SphereMesh.new();cap.radius = .09;cap.height = .12;dome.mesh = cap
	_lens = StandardMaterial3D.new();_lens.albedo_color = Color(.45, .03, .02);_lens.emission_enabled = true
	_lens.emission = Color(1, .08, .04);_lens.emission_energy_multiplier = 0.0
	dome.material_override = _lens;dome.position.y = -.03;add_child(dome)
	_rotor = Node3D.new();_rotor.position.y = -.03;add_child(_rotor)
	for side in [0.0, PI]:
		var spot := SpotLight3D.new();spot.light_color = Color(1, .12, .06);spot.light_energy = 0.0
		spot.spot_range = 9.0;spot.spot_angle = 30.0;spot.shadow_enabled = false;spot.light_volumetric_fog_energy = 3.0
		spot.rotation = Vector3(-.15, side, 0);_rotor.add_child(spot);_lights.append(spot)

func _process(delta: float) -> void:
	var hunting := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if absf(enemy.global_position.x - global_position.x) < RADIUS and enemy._state in [enemy.CHASE, enemy.WINDUP, enemy.SWING, enemy.RECOVERY]:
			hunting = true;break
	active = hunting or forced
	var target := 1.0 if active else 0.0
	var level := move_toward(_lights[0].light_energy / 14.0, target, delta * 2.5)
	for spot in _lights:spot.light_energy = level * 14.0
	_lens.emission_energy_multiplier = level * 4.0
	if level > 0.0:_rotor.rotation.y = wrapf(_rotor.rotation.y + SPIN * delta, 0.0, TAU)
