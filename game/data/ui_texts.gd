extends RefCounted
## Every in-game text of the UI modules (game/modules/ui/), by key. Texts are German
## today; moving them to English (E5) changes only the values here. Look a text up with
## `UI_TEXT.t("key")`; formatting (`%s`, `%d`) stays with the caller.

const TEXTS := {
	"sector_complete_back": "Zurück",
	"sector_complete_confirm": "Trotzdem zum Hauptmenü?\nUngespeicherter Fortschritt geht verloren.",
	"sector_complete_explore": "Weiter erkunden",
	"sector_complete_leave": "Verlassen",
	"sector_complete_none": "— keine —",
	"sector_complete_row_armor": "Rüstung",
	"sector_complete_row_guards": "Wachen",
	"sector_complete_row_shards": "Splitter",
	"sector_complete_row_weapon": "Waffe",
	"sector_complete_save_failed": "Speichern fehlgeschlagen — Fortschritt nur in dieser Sitzung.",
	"sector_complete_saved": "Fortschritt gespeichert",
	"sector_complete_sector": "Laborsektor 01",
	"sector_complete_title": "SEKTOR GESICHERT",
	"sector_complete_to_title": "Zum Hauptmenü",
}

static func t(key: String) -> String:
	if not TEXTS.has(key):
		push_error("ui text key missing: %s" % key)
		return key
	return TEXTS[key]

static func keys() -> Array:
	return TEXTS.keys()
