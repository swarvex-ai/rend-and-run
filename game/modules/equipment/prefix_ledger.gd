extends RefCounted
## Farming v0.2 foundation. Value state only; callers persist with equipment.
## Not yet exposed in gameplay: no loot source, shop button or attack modifier.
const UI_TEXT = preload("res://data/ui_texts.gd")
const CAP := 999999
const RECIPE := {"shards": 12, "servo": 2}
const MODULE := "servo_i"
# Restore normal-arm return speed while keeping reinforced windup/impact weight.
const RECOVERY_MULTIPLIER := 0.8

static func summary() -> String:
	return UI_TEXT.t("prefix_servo_summary") % roundi((1.0-RECOVERY_MULTIPLIER)*100.0)
var servo: int = 0
var _modules: Array[String] = []
var _installed: Dictionary = {}

func reset() -> void:
	servo = 0
	_modules.clear()
	_installed.clear()

static func bounded_count(value: Variant) -> int:
	if value is int:
		return clampi(value, 0, CAP)
	if value is float and is_finite(value) and value == floorf(value):
		return int(clampf(value, 0, CAP))
	return 0

func credit_servo(amount: int) -> int:
	var added := mini(maxi(amount, 0), CAP - servo)
	servo += added
	return added

func owns_module(id: String) -> bool:
	return _modules.has(id)

func can_craft(id: String, base_owned: bool, shards: int) -> String:
	if id != MODULE: return "unknown_module"
	if not base_owned: return "missing_base"
	if owns_module(id): return "already_owned"
	if shards < int(RECIPE.shards): return "insufficient_shards"
	if servo < int(RECIPE.servo): return "insufficient_servo"
	return ""

func _craft_validated() -> void:
	# Internal commit half: EquipmentLedger has validated both balances.
	servo -= int(RECIPE.servo)
	_modules.append(MODULE)

func install(base_id: String, module_id: String, base_owned: bool) -> bool:
	if base_id != "reinforced_arm" or not base_owned: return false
	if module_id.is_empty():
		_installed.erase(base_id)
		return true
	if module_id != MODULE or not owns_module(module_id): return false
	_installed[base_id] = module_id
	return true

func installed(base_id: String) -> String:
	return str(_installed.get(base_id, ""))

func recovery_multiplier(base_id: String) -> float:
	if base_id != "reinforced_arm": return 1.0
	return RECOVERY_MULTIPLIER if installed(base_id) == MODULE and owns_module(MODULE) else 1.0

func export_state() -> Dictionary:
	return {"version": 1, "materials": {"servo": servo},
		"modules": _modules.duplicate(), "installed": _installed.duplicate(true)}

func import_state(data: Variant) -> void:
	reset()
	if not data is Dictionary: return
	var materials: Variant = data.get("materials", {})
	if materials is Dictionary: servo = bounded_count(materials.get("servo", 0))
	var modules: Variant = data.get("modules", [])
	if modules is Array:
		for id in modules:
			# Retain future IDs without activating unimplemented effects.
			if id is String and not id.is_empty() and not _modules.has(id): _modules.append(id)
	var installed_raw: Variant = data.get("installed", {})
	if installed_raw is Dictionary:
		for base_id in installed_raw:
			var id: Variant = installed_raw[base_id]
			if base_id is String and id is String and _modules.has(id): _installed[base_id] = id
