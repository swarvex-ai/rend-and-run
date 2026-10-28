extends Node3D
## H60 authored shell, unchanged H29 grip/muzzle and per-instance charge API.
const MODEL = preload("res://assets3d/weapons/pulse_emitter_v101/model.glb")
const CHARGE_DIM := 0.15
const CHARGE_FULL := 2.2
var _charge := 0.0
var _charge_mat: StandardMaterial3D

func set_charge(amount: float) -> void:
	_charge = clampf(amount, 0.0, 1.0)
	if _charge_mat:
		_charge_mat.emission_energy_multiplier = lerpf(CHARGE_DIM, CHARGE_FULL, _charge)

func get_charge() -> float:
	return _charge

func _ready() -> void:
	var copied := get_child_count() > 0
	if not copied:
		add_child(MODEL.instantiate())
		var muzzle := Marker3D.new()
		muzzle.name = "Muzzle"
		muzzle.transform = Transform3D(Basis(Vector3(0,0,-1),Vector3(0,1,0),Vector3(1,0,0)),Vector3(0,0.700,0))
		add_child(muzzle)
	# Dropped weapon duplicates bring their children and surface overrides along.
	# Adopt the visible charge but never share mutable emission with another gun.
	for mesh in find_children("*", "MeshInstance3D", true, false):
		for index in mesh.mesh.get_surface_count():
			var material = mesh.get_active_material(index)
			if material is StandardMaterial3D and material.resource_name == "charge_cyan":
				_charge_mat = material.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(index, _charge_mat)
				if copied:
					_charge = clampf((_charge_mat.emission_energy_multiplier - CHARGE_DIM) / (CHARGE_FULL - CHARGE_DIM), 0.0, 1.0)
				_charge_mat.emission_enabled = true
				set_charge(_charge)
				return
	push_error("Pulse emitter has no charge_cyan material")
