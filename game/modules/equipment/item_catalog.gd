extends RefCounted
## Stable IDs for G02. Labels/effects describe current gameplay, not new balance.
## Player-visible texts live in res://data/ui_texts.gd and are read through label/summary/description.
## A resource_path may be a scene or a scripted visual; icons follow in the UI pass.
const UI_TEXT = preload("res://data/ui_texts.gd")
const ITEMS := {
	"robot_arm": {
		"icon_path":"res://assets/ui/equipment/robot_arm.svg",
		"slot":"weapon", "kind":"weapon", "cost":0,
		"acquisition":"world",
		"resource_path":"res://assets/models/weapon/weapon_arm_detached.glb",
		"effects":{"damage":1, "attack_speed":1.0}
	},
	"reinforced_arm": {
		"icon_path":"res://assets/ui/equipment/reinforced_arm.svg",
		"slot":"weapon", "kind":"weapon", "cost":6,
		"acquisition":"workbench",
		"resource_path":"res://assets/models/weapon/weapon_arm_detached.glb",
		"effects":{"damage":2, "attack_speed":0.8}
	},
	"salvage_shield": {
		"icon_path":"res://assets/ui/equipment/salvage_shield.svg",
		"slot":"shield", "kind":"unlock", "cost":6,
		"acquisition":"world",
		"resource_path":"res://shield_visual.gd",
		"effects":{"guard":true}
	},
	"lab_armor": {
		"icon_path":"res://assets/ui/equipment/lab_armor.svg",
		"slot":"armor", "kind":"armor", "cost":0,
		"acquisition":"world",
		"resource_path":"res://assets3d/weapons/lab_shoulder_plate.glb",
		"effects":{"max_hp_bonus":2}
	}
}

static func item(id: String) -> Dictionary:
	# Callers may format a copy without mutating canonical values or nested effects.
	return ITEMS[id].duplicate(true) if ITEMS.has(id) else {}

static func label(id: String) -> String:
	match id:
		"robot_arm": return UI_TEXT.t("item_robot_arm")
		"reinforced_arm": return UI_TEXT.t("item_reinforced_arm")
		"salvage_shield": return UI_TEXT.t("item_salvage_shield")
		"lab_armor": return UI_TEXT.t("item_lab_armor")
		_: return UI_TEXT.t("item_unknown")

static func summary(id: String) -> String:
	match id:
		"robot_arm": return UI_TEXT.t("item_robot_arm_summary")
		"reinforced_arm": return UI_TEXT.t("item_reinforced_arm_summary")
		"salvage_shield": return UI_TEXT.t("item_salvage_shield_summary")
		"lab_armor": return UI_TEXT.t("item_lab_armor_summary")
		_: return ""

static func description(id: String) -> String:
	match id:
		"robot_arm": return UI_TEXT.t("item_robot_arm_description")
		"reinforced_arm": return UI_TEXT.t("item_reinforced_arm_description")
		"salvage_shield": return UI_TEXT.t("item_salvage_shield_description")
		"lab_armor": return UI_TEXT.t("item_lab_armor_description")
		_: return ""
