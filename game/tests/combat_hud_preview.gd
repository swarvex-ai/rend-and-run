extends Control
## H25 — Optionale Standalone-Preview-Szene fuer Codex.
## Oeffnet: godot --path game res://tests/combat_hud_preview.tscn
## Zeigt das HUD in einem repraesentativen Zustand (ohne Spielcode).

const HUD := preload("res://modules/ui/combat_hud.gd")


func _ready() -> void:
	var hud := HUD.new()
	add_child(hud)
	hud.update_state({
		"hp": 2, "max_hp": 5, "stamina": 62.0,
		"shield_unlocked": true,
		"weapon_name": "Vibroklinge", "armor_name": "Lab-Panzerung",
		"shards": 7, "guards_defeated": 3, "guards_total": 9,
		"zone": "Labor-Sektor B", "objective": "Generatorschalt finden",
		"prompt": "[E] Konsole bedienen",
		"feedback": "Block erfolgt — Wache zurueckgeschlagen",
		"save_error": false, "help_visible": true,
	})
