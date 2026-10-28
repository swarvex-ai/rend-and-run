extends RigidBody3D
## A supply case Rend can shove, pick up and throw (Meshy case, asset_library/meshy/
## 2026-10-23_environment). Loose on the floor it is a physics body everyone collides with;
## carried it rides at Rend's hands without collision; thrown it flies in an arc and the
## first robot it strikes takes a heavy blow. Group "throwables".

signal struck(target: Node)

const SIZE := Vector3(.76, .62, .62)
const MODEL := preload("res://assets3d/env/factory_crate_v1/model.glb")
const DAMAGE := 2

var carried := false
var _thrown := false
var _thrown_time := 0.0
var _hit := {}

const DEPTH_MIN := -1.0
const DEPTH_MAX := 1.2

func _init() -> void:
	mass = 14.0
	collision_layer = 1           # world: blocks Rend, robots and shots like any prop
	collision_mask = 1 | 2 | 4
	contact_monitor = true;max_contacts_reported = 4
	can_sleep = true
	var pm := PhysicsMaterial.new();pm.friction = .6;pm.bounce = .05;physics_material_override = pm
	linear_damp = .4;angular_damp = 1.2
	axis_lock_angular_x = true    # tumbles about the depth axis only: stays readable in 2.5D
	axis_lock_angular_y = true
	var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = SIZE
	shape.shape = box;add_child(shape)
	var skin := MODEL.instantiate() as Node3D
	skin.name = "CaseSkin";skin.scale = Vector3.ONE * .4;add_child(skin)  # 1.9 x 1.54 x 1.56 m model
	body_entered.connect(_on_body_entered)
	add_to_group("throwables")

func pick_up() -> void:
	carried = true;_thrown = false
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;freeze = true
	collision_layer = 0;collision_mask = 0

## Leaves Rend's hands. velocity: world launch velocity (zero = just set down).
func release(velocity: Vector3) -> void:
	carried = false
	collision_layer = 1;collision_mask = 1 | 2 | 4
	freeze = false
	linear_velocity = velocity
	_thrown = velocity.length() > 2.0;_thrown_time = 0.0;_hit.clear()
	if _thrown:collision_mask = 1 | 2  # leaves Rend's hands without snagging on him
	if _thrown:angular_velocity = Vector3(0, 0, -signf(velocity.x) * 7.0)

func is_thrown() -> bool:
	return _thrown

func _physics_process(delta: float) -> void:
	# Thrown or shoved, it stays on the floor strip: never into the bays behind or out of view.
	if not carried and (global_position.z < DEPTH_MIN or global_position.z > DEPTH_MAX):
		global_position.z = clampf(global_position.z, DEPTH_MIN, DEPTH_MAX)
		linear_velocity.z = 0.0
	if not _thrown:return
	_thrown_time += delta
	# A thrown case is dangerous until it has landed and slowed down.
	if _thrown_time > 0.25 and linear_velocity.length() < 2.0:
		_thrown = false;collision_mask = 1 | 2 | 4

func _on_body_entered(body: Node) -> void:
	if not _thrown or _hit.has(body) or not body.has_method("take_melee_hit"):return
	if body.get("_dead") == true:return
	_hit[body] = true
	var push := Vector3(signf(linear_velocity.x) * 6.5, 2.0, 0)
	body.take_melee_hit(DAMAGE, push)
	FX.hitstop(0.07);FX.add_shake(0.35)
	FX.play("hit", 0.8, -1.0)
	linear_velocity = Vector3(-linear_velocity.x * 0.25, 2.5, 0)  # bounces back off the robot
	struck.emit(body)
