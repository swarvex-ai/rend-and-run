extends RefCounted
## Every in-game text of the UI modules (game/modules/ui/), by key. Texts are German
## today; moving them to English (E5) changes only the values here. Look a text up with
## `UI_TEXT.t("key")`; formatting (`%s`, `%d`) stays with the caller.

const TEXTS := {
	"checkpoint_error": "FEHLER",
	"checkpoint_ready": "BEREIT",
	"checkpoint_saved": "GESICHERT",
	"overseer_braced": "STANDHAFT",
	"overseer_phase": "Phase %d",
	"overseer_role": "LABOR-AUFSEHER",
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
	"workbench_back": "Zurück",
	"workbench_balance": "Splitter: %d · Servo: %d",
	"workbench_balance_initial": "Splitter: 0",
	"workbench_buy": "Kaufen · %d Splitter",
	"workbench_equip": "Ausrüsten",
	"workbench_equipped": "Ausgerüstet",
	"workbench_footer": "Eingabe / A: wählen · Esc / B: zurück",
	"workbench_missing_shards": "Es fehlen %d Splitter",
	"workbench_need_arm": "Zuerst den Humanoidenarm am Start bergen.",
	"workbench_servo_cost": "%d/12 Splitter · %d/2 Servo",
	"workbench_servo_craft": "Herstellen",
	"workbench_servo_install": "Anbauen",
	"workbench_servo_owned": "Modul im Besitz",
	"workbench_servo_remove": "Abbauen",
	"workbench_title": "WERKBANK",
	"workbench_trial_available": "Freiwillig: 12 Splitter + mindestens 1 Servo",
	"workbench_trial_done": "5/5 besiegt — übrige Teile einsammeln",
	"workbench_trial_info": "12 Splitter + 1 Servo sicher · Extra spätestens in %d %s",
	"workbench_trial_progress": "Bergung %d/5 — fortsetzen",
	"workbench_trial_run": "Lauf",
	"workbench_trial_runs": "Läufen",
	"workbench_trial_saved": "Fortschritt gespeichert · zurück in den Raum",
	"workbench_trial_start": "Servoteile bergen · 5 Roboter",
	"zone_airlock": "05 / SCHLEUSE",
	"zone_arrival": "01 / ANKUNFT",
	"zone_maintenance": "02 / WARTUNG",
	"zone_security": "04 / SICHERUNG",
	"zone_supply": "03 / VERSORGUNG",
}

static func t(key: String) -> String:
	if not TEXTS.has(key):
		push_error("ui text key missing: %s" % key)
		return key
	return TEXTS[key]

static func keys() -> Array:
	return TEXTS.keys()
