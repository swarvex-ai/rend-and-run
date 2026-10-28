extends SceneTree
## H31 — Start-Menue-Test UNTER tatsaechlich pausiertem Baum.
## Wie beim H30-Vorbild (4.7.2.arch headless ohne Fenster): synthetische
## push_input-Klicks aktivieren BaseButton nicht (Hover-Tracking braucht
## echtes Fenster); der Test emittiert btn.pressed wie die Engine nach echtem
## Klick und prueft Modul-Verdrahtung + Zustandsmaschine. grab_focus und
## Layout sind real. Aufruf:
## godot --headless --path game --script res://tests/start_menu_test.gd

var _fail := 0
var _checks := 0
var menu: Control

var n_continue := 0
var n_newrun := 0
var n_quit := 0

func _check(label: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("H31 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _press(btn: Button) -> void:
	btn.pressed.emit()

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

func _btn(nm: String) -> Button:
	return menu.find_child(nm, true, false) as Button

func _initialize() -> void:
	await process_frame
	menu = load("res://modules/ui/start_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu.continue_requested.connect(func() -> void: n_continue += 1)
	menu.new_run_requested.connect(func() -> void: n_newrun += 1)
	menu.quit_requested.connect(func() -> void: n_quit += 1)

	# --- Grundzustand / verbotene Aufrufe
	_check("initial_versteckt", not menu.visible)
	_check("process_mode_always", menu.process_mode == Node.PROCESS_MODE_ALWAYS)
	var src := FileAccess.get_file_as_string("res://modules/ui/start_menu.gd")
	_check("kein_process_polling", not src.contains("func _process"))
	# Der Vertrag verbietet Engine-Quit/Reload/Pause/FileIO — gesucht wird die
	# Aufrufform, nicht der Knotenname _on_quit selbst.
	_check("kein_quit_reload_pause_save_io", not src.contains("get_tree()") \
		and not src.contains(".paused") and not src.contains("get_tree().quit") \
		and not src.contains("reload_current_scene") \
		and not src.contains("FileAccess") and not src.contains("SaveGame"))
	var bd := menu.find_child("Backdrop", true, false) as ColorRect
	_check("backdrop_mouse_stop", bd != null and bd.mouse_filter == Control.MOUSE_FILTER_STOP)
	_check("echte_buttons", menu.find_children("*", "Button", true, false).size() >= 5)

	# --- ECHTE PAUSE: alles Folgende bei paused=true
	paused = true
	await process_frame

	var main_box := menu.find_child("MainBox", true, false) as Control
	var conf_box := menu.find_child("ConfirmBox", true, false) as Control

	# --- Fall OHNE Save
	menu.open_menu(false)
	await process_frame
	_check("ohne_save_sichtbar", menu.visible)
	_check("ohne_save_continue_deaktiviert", _btn("BtnContinue").disabled)
	_check("ohne_save_continue_nicht_fokussierbar", _btn("BtnContinue").focus_mode == Control.FOCUS_NONE)
	_check("ohne_save_fokus_neue_runde", _focus_name() == "BtnNewRun", _focus_name())
	_press(_btn("BtnNewRun"))
	await process_frame
	_check("ohne_save_newrun_sofort_1x", n_newrun == 1, "n=%d" % n_newrun)

	# --- Fall MIT Save: Fokus Fortsetzen, Neue Runde nur nach Bestaetigung
	menu.open_menu(true)
	await process_frame
	_check("mit_save_fokus_fortsetzen", _focus_name() == "BtnContinue", _focus_name())
	_check("mit_save_continue_aktiv", not _btn("BtnContinue").disabled \
		and _btn("BtnContinue").focus_mode == Control.FOCUS_ALL)
	_press(_btn("BtnContinue"))
	await process_frame
	_check("continue_1x", n_continue == 1, "n=%d" % n_continue)

	_press(_btn("BtnNewRun"))
	await process_frame
	await process_frame
	_check("mit_save_bestaetigung_offnet", conf_box.visible and not main_box.visible)
	_check("mit_save_kein_signal_vor_bestaetigung", n_newrun == 1, "n=%d" % n_newrun)
	_check("fokus_neue_runde_starten", _focus_name() == "BtnConfirmNewRun", _focus_name())
	_press(_btn("BtnBack"))
	await process_frame
	await process_frame
	_check("abbruch_zurueck_zu_haupt", main_box.visible and not conf_box.visible)
	_check("abbruch_fokus_neue_runde", _focus_name() == "BtnNewRun", _focus_name())
	_check("abbruch_kein_signal", n_newrun == 1, "n=%d" % n_newrun)
	_press(_btn("BtnNewRun"))
	await process_frame
	await process_frame
	_press(_btn("BtnConfirmNewRun"))
	await process_frame
	await process_frame
	_check("newrun_nach_bestaetigung_2x", n_newrun == 2, "n=%d" % n_newrun)

	# --- Beenden
	_press(_btn("BtnQuit"))
	await process_frame
	await process_frame
	_check("quit_1x", n_quit == 1, "n=%d" % n_quit)

	# --- Wiederholt oeffnen: Bestaetigung wird zurueckgesetzt, kein Knotenwachstum
	menu.open_menu(true)
	await process_frame
	_press(_btn("BtnNewRun"))
	await process_frame
	await process_frame
	_check("bestaetigung_offnet_erneut", conf_box.visible)
	menu.close_menu()
	menu.open_menu(true)
	await process_frame
	_check("reopen_setzt_bestaetigung_zurueck", main_box.visible and not conf_box.visible)
	_check("reopen_fokus_fortsetzen", _focus_name() == "BtnContinue", _focus_name())
	var before := _count_controls(menu)
	for i in range(10):
		menu.open_menu(true)
		menu.close_menu()
	await process_frame
	_check("kein_knotenwachstum", _count_controls(menu) == before, "before=%d after=%d" % [before, _count_controls(menu)])

	# --- Umlaute real vorhanden
	var txt_all := ""
	for c in menu.find_children("*", "Label", true, false):
		txt_all += (c as Label).text
	for c in menu.find_children("*", "Button", true, false):
		txt_all += (c as Button).text
	_check("umlautvorhanden", txt_all.contains("Zurück") and txt_all.contains("gespeicherte"), "")

	# --- Signale gesamt: continue 1, newrun 2 (1x ohne Save, 1x bestaetigt), quit 1
	_check("signale_konsistent", n_continue == 1 and n_newrun == 2 and n_quit == 1,
		"c=%d n=%d q=%d" % [n_continue, n_newrun, n_quit])

	# --- Layout 960x540..1920x1080: Panel im Viewport, Backdrop fullrect,
	#     Text der Fusszeile/Bestaetigung passt ohne Uberstand ins Panel
	for vp_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = vp_size
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
	print("H31 SUMMARY checks=%d failures=%d" % [_checks, _fail])
	quit(1 if _fail else 0)
