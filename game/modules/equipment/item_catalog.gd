extends RefCounted
## Stable IDs for G02. Labels/effects describe current gameplay, not new balance.
## A resource_path may be a scene or a scripted visual; icons follow in the UI pass.
const ITEMS := {
	"robot_arm": {
		"icon_path":"res://assets/ui/equipment/robot_arm.svg",
		"name":"Roboterarm", "slot":"weapon", "kind":"weapon", "cost":0,
		"acquisition":"world", "summary":"Schnelle Hiebe · 1 Schaden",
		"description":"Abgerissener Humanoidenarm. Die Hand dient als kompakter Schlagkopf.",
		"resource_path":"res://assets/models/weapon/weapon_arm_detached.glb",
		"effects":{"damage":1, "attack_speed":1.0}
	},
	"reinforced_arm": {
		"icon_path":"res://assets/ui/equipment/reinforced_arm.svg",
		"name":"Verstärkter Arm", "slot":"weapon", "kind":"weapon", "cost":6,
		"acquisition":"workbench", "summary":"Langsamere Hiebe · 2 Schaden",
		"description":"Mechanisch verstärkter Arm: mehr Wucht, längere Erholung.",
		"resource_path":"res://assets/models/weapon/weapon_arm_detached.glb",
		"effects":{"damage":2, "attack_speed":0.8}
	},
	"salvage_shield": {
		"icon_path":"res://assets/ui/equipment/salvage_shield.svg",
		"name":"Schrottschild", "slot":"shield", "kind":"unlock", "cost":6,
		"acquisition":"world", "summary":"Blocken und im richtigen Moment parieren",
		"description":"Improvisierter Schutz. Dauerhafte Abwehr kann gebrochen werden.",
		"resource_path":"res://shield_visual.gd",
		"effects":{"guard":true}
	},
	"lab_armor": {
		"icon_path":"res://assets/ui/equipment/lab_armor.svg",
		"name":"Laborpanzer", "slot":"armor", "kind":"armor", "cost":0,
		"acquisition":"world", "summary":"+2 maximale HP",
		"description":"Zusätzliche Schutzplatten aus dem Laborbestand.",
		"resource_path":"res://assets3d/weapons/lab_shoulder_plate.glb",
		"effects":{"max_hp_bonus":2}
	}
}

static func item(id: String) -> Dictionary:
	# Callers may format a copy without mutating canonical values or nested effects.
	return ITEMS[id].duplicate(true) if ITEMS.has(id) else {}

static func label(id: String) -> String:
	return str(ITEMS[id].name) if ITEMS.has(id) else "Unbekannter Gegenstand"

static func summary(id: String) -> String:
	return str(ITEMS[id].summary) if ITEMS.has(id) else ""
