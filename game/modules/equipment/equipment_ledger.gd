extends RefCounted
# H15 — Reines Ausruestungskauf-Ledger (Produktion, deterministisch).
# Kein class_name, keine Szene/Input/Datei/Netzwerk. Ziel-Ressourcenpfad:
# res://modules/equipment/equipment_ledger.gd
# Save-Format-Hoheit bleibt bei Codex: export/import ist ein reines
# value-Dictionary, das in vorhandene V12/V13-Staende eingebettet werden kann.

const MAX_SHARDS := 999999
const PREFIXES := preload("res://modules/equipment/prefix_ledger.gd")
var prefixes := PREFIXES.new()
const ITEMS := preload("res://modules/equipment/item_catalog.gd")

# Fester Produktionskatalog. Art: "unlock" oder "weapon".
const CATALOGUE := {
	"salvage_shield": ITEMS.ITEMS["salvage_shield"],
	"reinforced_arm": ITEMS.ITEMS["reinforced_arm"],
}

# Bewaffnete Optionen (Schild ist keine Waffe).
const WEAPONS := ["robot_arm", "reinforced_arm"]

var shards: int = 0
var _owned: Array[String] = []
var _equipped_weapon: String = ""
var _slots := {"armor":"", "shield":""}


func reset() -> void:
	prefixes.reset()
	shards = 0
	_owned.clear()
	_equipped_weapon = ""
	_slots = {"armor":"", "shield":""}


func credit(amount: int) -> int:
	# Ignoriert nicht-positive Betraege; harte Obergrenze MAX_SHARDS.
	# Rueckgabe: tatsaechlich gutgeschriebener Betrag.
	if amount <= 0:
		return 0
	var actual: int = mini(amount, MAX_SHARDS - shards)
	if actual <= 0:
		return 0
	shards += actual
	return actual


func owns(id: String) -> bool:
	return _owned.has(id)


func purchase(id: String) -> Dictionary:
	# Kauft genau einmal, atomar: Preis abzug + Eintrag nur bei Erfolg.
	# Kein Auto-Equip. Fehler lassen jeden Zustand unveraendert (spent 0).
	if not CATALOGUE.has(id):
		# robot_arm ist im Besitz, aber nicht im Kaufkatalog -> already_owned.
		if owns(id):
			return {"ok": false, "reason": "already_owned", "spent": 0}
		return {"ok": false, "reason": "unknown_item", "spent": 0}
	if id == "reinforced_arm" and not owns("robot_arm"):
		return {"ok": false, "reason": "missing_base", "spent": 0}
	if _owned.has(id):
		return {"ok": false, "reason": "already_owned", "spent": 0}
	var cost: int = int(CATALOGUE[id]["cost"])
	if shards < cost:
		return {"ok": false, "reason": "insufficient_shards", "spent": 0}
	shards -= cost
	_owned.append(id)
	return {"ok": true, "reason": "bought", "spent": cost}


func equipped_weapon() -> String:
	return _equipped_weapon


func equip_weapon(id: String) -> bool:
	# Erlaubt nur eigene Waffen; ein Kauf stattet niemals automatisch aus.
	if not WEAPONS.has(id) or not _owned.has(id):
		return false
	_equipped_weapon = id
	return true


func grant(id: String) -> bool:
	if not ITEMS.ITEMS.has(id):return false
	if not _owned.has(id):_owned.append(id)
	return true

func equipped(slot: String) -> String:
	return _equipped_weapon if slot=="weapon" else str(_slots.get(slot,""))

func equip(slot: String, id: String) -> bool:
	if slot=="weapon":return equip_weapon(id)
	if not _slots.has(slot):return false
	if not id.is_empty() and (not owns(id) or not ITEMS.ITEMS.has(id) or ITEMS.ITEMS[id].slot!=slot):return false
	_slots[slot]=id
	return true


func export_state() -> Dictionary:
	# Kopie: zurueckgegebenes owned-Array darf kein Fenster auf interne State sein.
	var owned_copy: Array[String] = []
	owned_copy.append_array(_owned)
	return {
		"loadout_version": 3,
		"prefixes": prefixes.export_state(),
		"slots": _slots.duplicate(),
		"shards": shards,
		"owned": owned_copy,
		"equipped_weapon": _equipped_weapon,
	}


func import_state(data: Dictionary) -> void:
	# Voller Reset auf Defaults, danach nur wohlgeformte Werte akzeptieren.
	# Import heftet nie implizit gut oder kauft ein.
	reset()
	if data.is_empty():
		return

	# shards: nicht-negativ, endlich, ganzzahlig (exakt-integer floats ok),
	# ueber dem Limit wird gekappt; alles andere ignoriert (bleibt 0).
	if data.has("shards"):
		var raw = data["shards"]
		var value := -1
		if typeof(raw) == TYPE_INT:
			value = raw
		elif typeof(raw) == TYPE_FLOAT and is_finite(raw) and raw == floorf(raw):
			value = int(minf(raw, MAX_SHARDS))
		if value >= 0:
			shards = mini(value, MAX_SHARDS)

	# Legacy swords migrate to mechanical arms, preserving earned equipment.
	var legacy := int(data.get("loadout_version", 1)) < 2
	if legacy:
		grant("robot_arm")
		_equipped_weapon = "robot_arm"
	# Only recognized IDs survive import.
	if data.has("owned"):
		var raw_owned = data["owned"]
		if typeof(raw_owned) == TYPE_ARRAY:
			for entry in raw_owned:
				if typeof(entry) != TYPE_STRING:
					continue
				if legacy: entry = {"starter_sword":"robot_arm", "vibroblade":"reinforced_arm"}.get(entry, entry)
				if not ITEMS.ITEMS.has(entry) or _owned.has(entry):
					continue
				_owned.append(entry)

	# equipped_weapon: nur eine eigene Waffe, sonst Default.
	if data.has("equipped_weapon"):
		var raw_eq = data["equipped_weapon"]
		if legacy and raw_eq is String: raw_eq = {"starter_sword":"robot_arm", "vibroblade":"reinforced_arm"}.get(raw_eq, raw_eq)
		if typeof(raw_eq) == TYPE_STRING and WEAPONS.has(raw_eq) and _owned.has(raw_eq):
			_equipped_weapon = raw_eq

	if owns("reinforced_arm") and not owns("robot_arm"): grant("robot_arm")
	if _equipped_weapon.is_empty() and owns("robot_arm"): _equipped_weapon = "robot_arm"
	var slots=data.get("slots",{})
	if slots is Dictionary:
		for slot in _slots:
			if slots.get(slot) is String:equip(slot,slots[slot])
	prefixes.import_state(data.get("prefixes", {}))
	if not owns("reinforced_arm"):
		# Keep module ownership, but an absent base cannot have an active module.
		prefixes.install("reinforced_arm", "", true)


func craft_module(id: String) -> Dictionary:
	var reason: String = prefixes.can_craft(id, owns("reinforced_arm"), shards)
	if not reason.is_empty(): return {"ok": false, "reason": reason, "spent": {}}
	# One synchronous value transaction; caller must persist before success UI.
	shards -= int(PREFIXES.RECIPE.shards)
	prefixes._craft_validated()
	return {"ok": true, "reason": "crafted", "spent": PREFIXES.RECIPE.duplicate()}

func install_module(base_id: String, module_id: String) -> bool:
	return prefixes.install(base_id, module_id, owns(base_id))
