extends SceneTree
## H32 — Sektorabschluss-Test UNTER tatsaechlich pausiertem Baum.
## Wie H30/H31 (4.7.2.arch headless ohne Fenster): synthetische push_input-
## Klicks aktivieren BaseButton nicht; der Test emittiert btn.pressed wie die
## Engine nach echtem Klick und prueft Verdrahtung + Zustandsmaschine.
## godot --headless --path game --script res://tests/sector_complete_test.gd

var _fail := 0
var _checks := 0
var menu: Control

var n_explore := 0
var n_title := 0

func _check(label: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("H32 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _press(btn: Button) -> void:
	btn.pressed.emit()

func _btn(nm: String) -> Button:
	return menu.find_child(nm, true, false) as Button

func _val(nm: String) -> String:
	return (menu.find_child("Val_" + nm, true, false) as Label).text

func _count_controls(n: Node) -> int:
	var c := 0
	if n is Control:
		c += 1
	for k in n.get_children():
		c += _count_controls(k)
	return c

func _focus_name() -> String:
	var fo := menu.get_viewport().gui_get_focus_owner()
	return str(fo.name) if fo != null else "<none>"

func _state(save_ok: bool) -> Dictionary:
	return {
		"guards_defeated": 7, "guards_total": 8, "shards": 12,
		"weapon_name": "Puls-Emitter Mk. IV", "armor_name": "Leichtpanzer Mk. II",
		"save_ok": save_ok,
	}

func _initialize() -> void:
	await process_frame
	menu = load("res://modules/ui/sector_complete.gd").new()
	root.add_child(menu)
	await process_frame
	menu.explore_requested.connect(func() -> void: n_explore += 1)
	menu.title_requested.connect(func() -> void: n_title += 1)

	# --- Grundzustand / verbotene Aufrufe
	_check("initial_versteckt", not menu.visible)
	_check("process_mode_always", menu.process_mode == Node.PROCESS_MODE_ALWAYS)
	var src := FileAccess.get_file_as_string("res://modules/ui/sector_complete.gd")
	_check("kein_process_polling", not src.contains("func _process"))
	_check("kein_pause_reload_quit_fileio", not src.contains("get_tree()") \
		and not src.contains(".paused") and not src.contains("reload_current_scene") \
		and not src.contains("FileAccess") and not src.contains("SaveGame"))
	# keine erfundenen Rewards/Raenge im Modul (Kommentar-/StyleBox-Treffer
	# waeren False-Positives — erfundene Belohnungen prueft der Sichttext-Check)
	_check("kein_score_timerrang_im_modul", not src.contains("score") \
		and not src.contains("elapsed") and not src.contains("kill_count"))
	var bd := menu.find_child("Backdrop", true, false) as ColorRect
	_check("backdrop_mouse_stop", bd != null and bd.mouse_filter == Control.MOUSE_FILTER_STOP)
	_check("echte_buttons", menu.find_children("*", "Button", true, false).size() >= 4)

	# --- ECHTE PAUSE
	paused = true
	await process_frame

	var main_box := menu.find_child("MainBox", true, false) as Control
	var conf_box := menu.find_child("ConfirmBox", true, false) as Control
	var save_lbl := menu.find_child("SaveStatus", true, false) as Label

	# --- Fall SPEICHERN OK: echte Werte, Fokus Explore, Hauptmenue ohne Umweg
	menu.show_summary(_state(true))
	await process_frame
	_check("show_sichtbar", menu.visible)
	_check("werte_echt_wachen", _val("Wachen") == "7 / 8", _val("Wachen"))
	_check("werte_echt_splitter", _val("Splitter") == "12", _val("Splitter"))
	_check("werte_echt_waffe", _val("Waffe") == "Puls-Emitter Mk. IV", _val("Waffe"))
	_check("werte_echt_ruestung", _val("Rüstung") == "Leichtpanzer Mk. II", _val("Rüstung"))
	_check("save_ok_text", save_lbl.text == "Fortschritt gespeichert", save_lbl.text)
	_check("initialefokus_explore", _focus_name() == "BtnExplore", _focus_name())
	_check("mainbox_sichtbar_bestaetigung_nein", main_box.visible and not conf_box.visible)
	_press(_btn("BtnExplore"))
	await process_frame
	_check("explore_1x", n_explore == 1, "n=%d" % n_explore)
	_press(_btn("BtnTitle"))
	await process_frame
	_check("title_ok_ohne_bestaetigung_1x", n_title == 1, "n=%d" % n_title)
	_check("title_ok_kein_confirm", not conf_box.visible)

	# --- Fall SPEICHERFEHLER: Warntext, Hauptmenue nur mit Bestaetigung
	menu.show_summary(_state(false))
	await process_frame
	_check("save_fail_text", save_lbl.text == "Speichern fehlgeschlagen — Fortschritt nur in dieser Sitzung.", save_lbl.text)
	_check("fehler_mainbox_reset", main_box.visible and not conf_box.visible)
	_press(_btn("BtnTitle"))
	await process_frame
	await process_frame
	_check("fehler_confirm_offnet", conf_box.visible and not main_box.visible)
	_check("fehler_kein_signal_vor_bestaetigung", n_title == 1, "n=%d" % n_title)
	_check("fehler_fokus_verlassen", _focus_name() == "BtnLeave", _focus_name())
	_press(_btn("BtnBack"))
	await process_frame
	await process_frame
	_check("fehler_abbruch_zurueck", main_box.visible and not conf_box.visible)
	_check("fehler_abbruch_fokus_explore", _focus_name() == "BtnExplore", _focus_name())
	_check("fehler_abbruch_kein_signal", n_title == 1, "n=%d" % n_title)
	# Explore bleibt im Fehlerfall sicher
	_press(_btn("BtnExplore"))
	await process_frame
	_check("fehler_explore_sicher", n_explore == 2, "n=%d" % n_explore)
	_press(_btn("BtnTitle"))
	await process_frame
	await process_frame
	_press(_btn("BtnLeave"))
	await process_frame
	await process_frame
	_check("title_nach_bestaetigung_2x", n_title == 2, "n=%d" % n_title)

	# --- Erneutes show_summary: Bestaetigung zurueck, neue Werte, kein Wachstum
	menu.show_summary(_state(false))
	await process_frame
	_press(_btn("BtnTitle"))
	await process_frame
	await process_frame
	_check("confirm_offnet_erneut", conf_box.visible)
	menu.show_summary({"guards_defeated": 2, "guards_total": 8, "shards": 3,
		"weapon_name": "", "armor_name": "", "save_ok": true})
	await process_frame
	_check("reopen_setzt_confirm_zurueck", main_box.visible and not conf_box.visible)
	_check("werte_aktualisiert", _val("Wachen") == "2 / 8" and _val("Splitter") == "3", _val("Wachen"))
	_check("leere_ausruestung_platzhalter", _val("Waffe") == "— keine —" and _val("Rüstung") == "— keine —", _val("Waffe"))
	var before := _count_controls(menu)
	for i in range(10):
		menu.show_summary(_state(true))
		menu.close_summary()
	menu.show_summary(_state(false))
	await process_frame
	_check("kein_knotenwachstum", _count_controls(menu) == before, "before=%d after=%d" % [before, _count_controls(menu)])

	# --- sichtbarer Text: Umlaute echt, keine Technik-/Rewardwoerter
	var txt_all := ""
	for c in menu.find_children("*", "Label", true, false):
		txt_all += (c as Label).text + "\n"
	for c in menu.find_children("*", "Button", true, false):
		txt_all += (c as Button).text + "\n"
	_check("umlauten_echt", txt_all.contains("Zum Hauptmenü") and txt_all.contains("Zurück") \
		and txt_all.contains("SEKTOR GESICHERT") and txt_all.contains("Rüstung"), "")
	_check("sichtbar_keine_technik_reworts", not txt_all.to_lower().contains("save") \
		and not txt_all.to_lower().contains("signal") and not txt_all.to_lower().contains("bool"))

	# --- Signalbilanz
	_check("signale_konsistent", n_explore == 2 and n_title == 2, "e=%d t=%d" % [n_explore, n_title])

	# --- Layout: Panel im Viewport, Backdrop fullrect, lange Texte umbrochen im Panel
	var long_state := {"guards_defeated": 128, "guards_total": 128, "shards": 99999,
		"weapon_name": "Experimental-Puls-Emitter Mk. VII mit langem Zusatznamen",
		"armor_name": "Verstaerkte Labor-Rüstung mit langem Zusatznamen", "save_ok": false}
	for vp_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = vp_size
		menu.show_summary(long_state)
		await process_frame
		await process_frame
		var panel := menu.find_child("Panel", true, false) as Control
		var pr: Rect2 = panel.get_global_rect()
		_check("panel_im_viewport_%dx%d" % [vp_size.x, vp_size.y],
			pr.position.x >= 0 and pr.position.y >= 0 \
			and pr.end.x <= float(vp_size.x) + 0.5 and pr.end.y <= float(vp_size.y) + 0.5, str(pr))
		var br: Rect2 = (menu.find_child("Backdrop", true, false) as Control).get_global_rect()
		_check("backdrop_fullrect_%dx%d" % [vp_size.x, vp_size.y],
			absf(br.size.x - float(vp_size.x)) < 1.0 and absf(br.size.y - float(vp_size.y)) < 1.0, str(br.size))
		var fit_ok := true
		for c in menu.find_children("*", "Label", true, false):
			var lr: Rect2 = (c as Control).get_global_rect()
			if lr.size.x > pr.size.x + 1.0 or lr.end.y > pr.end.y + 1.0:
				fit_ok = false
		_check("labels_passen_ins_panel_%dx%d" % [vp_size.x, vp_size.y], fit_ok)

	paused = false
	print("H32 SUMMARY checks=%d failures=%d" % [_checks, _fail])
	quit(1 if _fail else 0)
