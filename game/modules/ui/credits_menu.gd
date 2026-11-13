extends "res://modules/ui/menu_screen.gd"
## CreditsMenu: Credits screen reachable from the main menu (E11.6a, baseline G-13).
## Shows credits sections mirrored from CREDITS.md via credits_data.gd, plus a Back row.
## B / Esc (ui_cancel) and the Back row emit back_requested.

const CreditsData = preload("res://data/credits_data.gd")

func _init() -> void:
	super._init()
	name = "CreditsMenu"
	title = "Credits"

func _build() -> void:
	for i in CreditsData.SECTIONS.size():
		var section: Dictionary = CreditsData.SECTIONS[i]
		var section_title: String = section.get("title", "")
		var lines: Array = section.get("lines", [])
		var text := section_title
		if not lines.is_empty():
			text += "\n" + "\n".join(lines)
		add_button("section_%d" % i, text)
	add_button("back", "Back")
	row_activated.connect(_on_row_activated)

func _on_row_activated(id: String) -> void:
	if id == "back":
		back_requested.emit()
