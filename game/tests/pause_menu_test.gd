extends SceneTree
## H30 — Pause-Menue-Test UNTER tatsaechlich pausiertem Baum.
## Oeffnet das Menue, setzt paused=true und prueft dann Zustandsmaschine,
## Signale, Fokus und Layout.
##
## WICHTIG — Headless-Eingabelimit (Godot 4.7.2.arch, kein Fenster): ein per
## push_input/parse_input_event gesendeter Klick erreicht das Control wohl
## (per gui_input-Sonde bestaetigt), aber BaseButton emittiert 'pressed' nur
## bei aktivem Hover-Tracking, das ein echtes Fenster braucht (warp_mouse
## greift nicht im headless DisplayServer). Die Engine-Klick-Maschine ist
## NICHT das Ausliefergut dieses Moduls. Geprueft wird die Modul-Verdrahtung:
## ein Button-'pressed' — emittiert wie von der Engine nach echtem Klick —
## muss exakt ein Modulsignal ausloesen. Live-Klicks mit Fenster prueft Codex.
## Aufruf: godot --headless --path game --script res://tests/pause_menu_test.gd

var _fail := 0
var _checks := 0
var menu: Control

var n_resume := 0
var n_restart := 0
var n_quit := 0

func _check(label: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("H30 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

## Betraetigt einen Button so, wie die Engine es nach einem echten Klick tut:
## 'pressed' emittieren. Das prueft die Modul-Verdrahtung (Handler -> Signal).
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

func _initialize() -> void:
	await process_frame
	menu = load("res://modules/ui/pause_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu.resume_requested.connect(func() -> void: n_resume += 1)
	menu.restart_requested.connect(func() -> void: n_restart += 1)
	menu.quit_requested.connect(func() -> void: n_quit += 1)

	# --- Grundzustand
	_check("initial_versteckt", not menu.visible)
	_check("process_mode_always", menu.process_mode == Node.PROCESS_MODE_ALWAYS)
	var bd := menu.find_child("Backdrop", true, false) as ColorRect
	_check("backdrop_mouse_stop", bd != null and bd.mouse_filter == Control.MOUSE_FILTER_STOP)
	var src := FileAccess.get_file_as_string("res://modules/ui/pause_menu.gd")
	_check("kein_process_polling", not src.contains("func _process"))
	_check("kein_quit_reload_pause_save_io", not src.contains("get_tree().quit") \
		and not src.contains("reload_current_scene") and not src.contains(".paused = true") \
		and not src.contains("SaveGame"))
	_check("echte_buttons", menu.find_children("*", "Button", true, false).size() >= 5)

	# --- ECHTE PAUSE des Baums: alles Folgende laeuft bei paused=true
	# (SceneTree-Skriptmodus: kein get_tree() — der SceneTree IST der Baum)
	paused = true
	await process_frame

	# --- open_menu: sichtbar + Fokus Weiter (Fokus greift unter Pause)
	menu.open_menu()
	await process_frame
	_check("open_sichtbar", menu.visible)
	_check("fokus_weiter", _focus_name() == "BtnResume", _focus_name())

	_check("hauptansicht_sichtbar", menu.confirm_id == "" and menu.rows.size() == 5)

	# --- Weiter emittiert resume_requested genau einmal
	_press(menu.find_child("BtnResume", true, false) as Button)
	await process_frame
	_check("resume_genau_einmal", n_resume == 1, "n=%d" % n_resume)

	# --- Restart: erst Bestaetigung, erst der zweite Klick emittiert
	_press(menu.find_child("BtnRestart", true, false) as Button)
	await process_frame
	await process_frame
	_check("bestaetigung_offnet", menu.confirm_id == "restart" and menu.rows.size() == 2)
	_check("keine_restart_signal_vor_bestaetigung", n_restart == 0, "n=%d" % n_restart)
	_check("fokus_neu_laden", _focus_name() == "BtnReload", _focus_name())
	_press(menu.find_child("BtnReload", true, false) as Button)
	await process_frame
	await process_frame
	_check("restart_genau_einmal_nach_bestaetigung", n_restart == 1, "n=%d" % n_restart)

	# --- Abbruchpfad: Zurueck fuehrt zu den Hauptbuttons, kein restart-Signal
	menu.open_menu()
	await process_frame
	_press(menu.find_child("BtnRestart", true, false) as Button)
	await process_frame
	await process_frame
	_check("bestaetigung_offnet_2", menu.confirm_id == "restart" and menu.rows.size() == 2)
	_press(menu.find_child("BtnBack", true, false) as Button)
	await process_frame
	await process_frame
	_check("abbruch_zurueck_zu_haupt", menu.confirm_id == "" and menu.rows.size() == 5)
	_check("abbruch_fokus_kontrollpunkt", _focus_name() == "BtnRestart", _focus_name())
	_check("abbruch_kein_zusaetzliches_restart", n_restart == 1, "n=%d" % n_restart)

	# --- Beenden emittiert quit_requested genau einmal
	_press(menu.find_child("BtnQuit", true, false) as Button)
	await process_frame
	await process_frame
	_press(menu.rows[1].node as Button)
	await process_frame
	_check("quit_genau_einmal", n_quit == 1, "n=%d" % n_quit)

	# --- close / reopen: offene Bestaetigung wird verworfen, Fokus Weiter
	menu.close_menu()
	_check("close_versteckt", not menu.visible)
	menu.open_menu()
	await process_frame
	_press(menu.find_child("BtnRestart", true, false) as Button)
	await process_frame
	await process_frame
	_check("in_bestaetigung_vor_reopen", menu.confirm_id == "restart" and menu.rows.size() == 2)
	menu.close_menu()
	menu.open_menu()
	await process_frame
	_check("reopen_setzt_bestaetigung_zurueck", menu.confirm_id == "" and menu.rows.size() == 5)
	_check("reopen_fokus_weiter", _focus_name() == "BtnResume", _focus_name())

	# --- kein Knotenwachstum nach 10 Oeffnen/Schliessen
	var before := _count_controls(menu)
	for i in range(10):
		menu.open_menu()
		menu.close_menu()
	await process_frame
	_check("kein_knotenwachstum", _count_controls(menu) == before, "before=%d after=%d" % [before, _count_controls(menu)])

	# --- Signale insgesamt: je Aktivierung exakt einmal
	_check("signale_konsistent", n_resume == 1 and n_restart == 1 and n_quit == 1,
		"r=%d rs=%d q=%d" % [n_resume, n_restart, n_quit])

	# --- Lesbarkeit: alle Schriftelemente >= 18 px
	var min_font := 999
	for c in menu.find_children("*", "Label", true, false):
		min_font = mini(min_font, (c as Control).get_theme_font_size("font_size"))
	for c in menu.find_children("*", "Button", true, false):
		min_font = mini(min_font, (c as Control).get_theme_font_size("font_size"))
	_check("schrift_min_18px", min_font >= 18, "min=%d" % min_font)

	# --- Layout 960x540..1920x1080: Panel im Viewport, Backdrop fullrect
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

	paused = false
	print("H30 SUMMARY checks=%d failures=%d" % [_checks, _fail])
	quit(1 if _fail else 0)
