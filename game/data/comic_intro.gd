extends RefCounted
## Comic intro script (variant 1): five panels, 48 seconds total, from a quiet
## night desk to the factory floor. Captions and the facility PA line are comic
## script data and are deliberately not kept in ui_texts.gd. Art paths point at
## res://assets/comic/; until the art lands the comic player shows a placeholder
## plate for each panel instead.

const PANELS := [
	{
		"art": "res://assets/comic/intro_panel_01_art.png",
		"duration_s": 10.0,
		"caption": "Rend spends his nights teaching machines to move.",
		"pa": "",
		"sfx": "",
	},
	{
		"art": "res://assets/comic/intro_panel_02_art.png",
		"duration_s": 9.0,
		"caption": "Every screen turns red.",
		"pa": "",
		"sfx": "",
	},
	{
		"art": "res://assets/comic/intro_panel_03_art.png",
		"duration_s": 9.0,
		"caption": "They were built to serve. Tonight they move like hunters.",
		"pa": "",
		"sfx": "",
	},
	{
		"art": "res://assets/comic/intro_panel_04_art.png",
		"duration_s": 8.0,
		"caption": "Everything goes dark.",
		"pa": "",
		"sfx": "",
	},
	{
		"art": "res://assets/comic/intro_panel_05_art.png",
		"duration_s": 12.0,
		"caption": "Rend wakes where the machines are born.",
		"pa": "Unregistered intruder on the factory floor. Security units dispatched.",
		"sfx": "",
	},
]

static func total_duration() -> float:
	var total := 0.0
	for panel in PANELS:
		total += panel["duration_s"]
	return total
