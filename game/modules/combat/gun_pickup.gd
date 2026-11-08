extends Node3D
## A dropped firearm lying on the floor strip with a soft amber halo, until Rend takes it
## (lab_route offers "E / Y — <name> aufnehmen" within reach). Group "gun_pickups".

var kind := "pistol"
var ammo := 0
var _gun: Node3D
var _halo: OmniLight3D
var _t := 0.0

static func drop(parent: Node, at: Vector3, gun_kind: String, rounds: int) -> Node3D:
	var pickup: Node3D = (load("res://modules/combat/gun_pickup.gd") as GDScript).new()
	pickup.kind = gun_kind;pickup.ammo = rounds;pickup.name = "GunPickup_" + gun_kind
	parent.add_child(pickup)
	pickup.global_position = Vector3(at.x, 0.0, clampf(at.z, -1.0, 1.2))
	return pickup

func _ready() -> void:
	add_to_group("gun_pickups")
	_gun = preload("res://modules/combat/gun.gd").make(kind)
	add_child(_gun)
	# Lies on its side across the strip, barrel along the floor.
	_gun.rotation = Vector3(PI / 2, 0, -PI / 2)
	_gun.position.y = 0.06
	_halo = OmniLight3D.new();_halo.light_color = Color(1.0, 0.7, 0.3);_halo.light_energy = 0.6
	_halo.omni_range = 0.9;_halo.shadow_enabled = false;_halo.position.y = 0.25;add_child(_halo)

func label() -> String:
	return preload("res://modules/combat/gun.gd").label_of(kind)

func _process(delta: float) -> void:
	_t += delta
	_halo.light_energy = 0.45 + sin(_t * 4.0) * 0.2
