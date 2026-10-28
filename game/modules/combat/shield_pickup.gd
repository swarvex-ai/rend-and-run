extends Node3D
## A shield lying on the floor strip (a security robot's riot shield, or the chest plate Rend
## swapped away) until he takes it; lab_route offers the swap within reach. Group "shield_pickups".

var kind := "riot"
var _halo: OmniLight3D
var _t := 0.0

static func drop(parent: Node, at: Vector3, shield_kind: String) -> Node3D:
	var pickup: Node3D = (load("res://modules/combat/shield_pickup.gd") as GDScript).new()
	pickup.kind = shield_kind;pickup.name = "ShieldPickup_" + shield_kind
	parent.add_child(pickup)
	pickup.global_position = Vector3(at.x, 0.0, clampf(at.z, -1.0, 1.2))
	return pickup

func label() -> String:
	return "Einsatzschild" if kind == "riot" else "Schrottschild"

func _ready() -> void:
	add_to_group("shield_pickups")
	var visual := preload("res://shield_visual.gd").new();visual.kind = kind;add_child(visual)
	visual.rotation = Vector3(-PI / 2, 0, 0)  # lies face up
	visual.position.y = 0.06
	_halo = OmniLight3D.new();_halo.light_color = Color(1.0, 0.7, 0.3);_halo.light_energy = 0.6
	_halo.omni_range = 1.0;_halo.shadow_enabled = false;_halo.position.y = 0.3;add_child(_halo)

func _process(delta: float) -> void:
	_t += delta
	_halo.light_energy = 0.45 + sin(_t * 4.0) * 0.2
