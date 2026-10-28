extends StaticBody3D
# H13 — Zerstörbare Versorgungskiste (Standalone-Modul).
# Kein FX, kein Audio, keine Debris-Physik, kein user://, kein Zugriff auf Player/Hauptszene.
# Kollision Layer 2 / Maske 1: von Rends HitArea (Maske 2) erfassbar, nicht Teil der
# "enemies"-Gruppe, daher ohne Einfluss auf Gate-/Encounter-Zaehler.

signal broken(crate_id: String, amount: int, origin: Vector3)

@export var crate_id: String = "supply"
@export var hit_points: int = 2
@export var reward_amount: int = 3

const SIZE := Vector3(0.65, 0.65, 0.55)  # XYZ; Root-Ursprung an den Fuessen

var _hp := -1                 # -1 = noch nicht initialisiert (Export gilt beim ersten Zugriff)
var _broken := false
var _collider: CollisionShape3D
var _visual: Node3D

func _ready() -> void:
	add_to_group("metal_props")
	# World layer too: Rend and robots walk around crates on the floor strip, blows still hit them.
	collision_layer = 1 | 2
	collision_mask = 1
	_build()
	if _hp < 0:
		_hp = hit_points
	_apply_state()

func take_melee_hit(damage: int, knockback: Vector3) -> void:
	# Ignoriert Null-/Negativ-Schaden; Uebergang bei HP<=0 passiert genau einmal.
	if _broken or damage <= 0:
		return
	if _hp < 0:
		_hp = hit_points
	_hp -= damage
	if _hp <= 0:
		_broken = true
		_apply_state()
		broken.emit(crate_id, maxi(0, reward_amount), global_position)

func restore_broken(value: bool) -> void:
	# Setzt reinen Zustand — emittiert NIEMALS broken/belohnt nicht.
	# Funktioniert vor UND nach _ready (Kollision wird deferred angepasst).
	_broken = value
	_hp = 0 if value else hit_points
	_apply_state()

func is_broken() -> bool:
	return _broken

func _apply_state() -> void:
	if _collider == null:
		return  # vor _ready; _ready ruft erneut auf, sobald der Baum steht
	_visual.set_broken(_broken)
	_collider.set_deferred("disabled", _broken)

func _build() -> void:
	_visual = preload("res://modules/visuals/supply_crate_visual.gd").new()
	_visual.name = "CrateVisual"
	# Fit the decorative model to the existing gameplay collision footprint.
	_visual.scale = Vector3(SIZE.x / 0.86, SIZE.y / 0.72, SIZE.z / 0.741)
	add_child(_visual)
	_collider = CollisionShape3D.new()
	_collider.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = SIZE
	_collider.shape = shape
	_collider.position = Vector3(0.0, SIZE.y * 0.5, 0.0)
	add_child(_collider)
