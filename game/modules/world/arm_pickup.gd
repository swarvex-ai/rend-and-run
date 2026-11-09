extends Node3D
## The owner handles input, ownership and persistence; this node is presentation only.
const MODEL = preload("res://assets/models/weapon/weapon_arm_detached.glb")
const UI_TEXT = preload("res://data/ui_texts.gd")
var collected := false
var focused := false
var _arm: Node3D
var _light: OmniLight3D
var _label: Label3D

func _ready() -> void:
	name = "ArmSalvage"
	_arm = MODEL.instantiate()
	_arm.name = "SalvageArm"
	_arm.position = Vector3(-0.16, 0.814, 0) # Measured arm underside rests 1mm above the .81m tray.
	_arm.rotation.z = -PI / 2.0
	add_child(_arm)
	var cart := preload("res://assets3d/env/salvage_cart_v1/model.glb").instantiate() as Node3D
	cart.name="SalvageCart"
	cart.position.y=-.05 # Pickup origin is 5cm above floor; caster bottoms remain on Y0.
	add_child(cart)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 1.2, 0.25)
	_light.light_color = Color(0.25, 0.82, 0.90)
	_light.light_energy = 0.35
	_light.omni_range = 1.5
	_light.shadow_enabled = false
	add_child(_light)
	_label = Label3D.new()
	_label.text = UI_TEXT.t("arm_pickup_prompt")
	_label.position = Vector3(0, 1.42, 0)
	_label.font_size = 24
	_label.pixel_size = 0.0035
	_label.modulate = Color(0.55, 0.93, 0.95)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.visible = false  # the HUD prompt names the action; the glowing arm draws the eye
	add_child(_label)
	set_collected(collected)

func can_reach(actor_position: Vector3) -> bool:
	return not collected and absf(actor_position.x-global_position.x) <= 1.25 \
		and absf(actor_position.y-global_position.y) <= 0.9 \
		and absf(actor_position.z-global_position.z) <= 1.0

func set_collected(value: bool) -> void:
	collected = value
	if value: set_focused(false)
	if _arm: _arm.visible = not value
	if _light: _light.visible = not value

func set_focused(value: bool) -> void:
	value = value and not collected
	if focused == value: return
	focused = value
	if _light: _light.light_energy = 1.15 if focused else 0.35
