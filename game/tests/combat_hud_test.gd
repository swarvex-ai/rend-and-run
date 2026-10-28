extends SceneTree
## H25 — Tests fuer combat_hud.gd (standalone, headless).
## Prueft an der ECHTEN Control-Baumstruktur: Maus-Ignore ueberall, Panelbudget,
## Clamping (Low-HP/Zero-Max/ausserhalb), Schild-Toggle, leerer Prompt versteckt,
## Save-Warnung sichtbar, Hilfe nur bei help_visible, F1-Footer immer, kein F5 im
## HUD, 100x update_state ohne Knotenwachstum, Layout 960x540 ohne Ueberlappung.
## Aufruf: godot --headless --path <scratch> --script res://tests/combat_hud_test.gd

const HUD := preload("res://modules/ui/combat_hud.gd")

var failures := 0
var checks := 0

func check(label: String, ok: bool, detail := "") -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H25 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _all(n: Node, out: Array) -> void:
	for c in n.get_children():
		out.append(c)
		_all(c, out)

func _controls(hud: Node) -> Array:
	var out: Array = []
	_all(hud, out)
	return out

func _visible_text(n: Node) -> String:
	var t := ""
	for c in _controls(n):
		if c is Label and (c as Control).visible:
			t += (c as Label).text + "\n"
	return t

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	await process_frame

	# --- 1) Grundgeruest --------------------------------------------------------
	check("Control-Wurzel mit FULL_RECT-Ankern",
		hud.anchor_right >= 0.99 and hud.anchor_bottom >= 0.99)
	var no_ignore := 0
	for c in _controls(hud):
		if c is Control and (c as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			no_ignore += 1
	check("mouse_filter IGNORE auf ALLEN Controls", no_ignore == 0, "abweichend=%d" % no_ignore)
	var nodes0 := _controls(hud).size()
	check("echte Control-Struktur vorhanden", nodes0 >= 10, "n=%d" % nodes0)

	var panel := hud.find_child("StatusPanel", true, false) as Control
	var hp_label := hud.find_child("HpLabel", true, false) as Label
	var stamina := hud.find_child("StaminaBar", true, false) as ProgressBar
	var gear := hud.find_child("GearLabel", true, false) as Label
	var zone := hud.find_child("ZoneLabel", true, false) as Label
	var guards := hud.find_child("GuardsLabel", true, false) as Label
	var shards := hud.find_child("ShardsLabel", true, false) as Label
	var objective := hud.find_child("ObjectiveLabel", true, false) as Label
	var prompt := hud.find_child("PromptLabel", true, false) as Label
	var feedback := hud.find_child("FeedbackLabel", true, false) as Label
	var save_warn := hud.find_child("SaveWarn", true, false) as Label
	var help_panel := hud.find_child("HelpPanel", true, false) as Control
	check("alle benannten Controls auffindbar",
		panel != null and hp_label != null and stamina != null and gear != null
		and zone != null and guards != null and shards != null and objective != null
		and prompt != null and feedback != null and save_warn != null and help_panel != null)

	# --- 2) Vollstaendiger Zustand ------------------------------------------------
	hud.update_state({
		"hp": 2, "max_hp": 5, "stamina": 62.0, "shield_unlocked": true,
		"weapon_name": "Vibroklinge", "armor_name": "Lab-Panzerung",
		"shards": 7, "guards_defeated": 3, "guards_total": 9,
		"zone": "Labor B", "objective": "Schalt finden",
		"prompt": "[E] Konsole", "feedback": "Block ok",
		"save_error": false, "help_visible": false})
	await process_frame
	check("HP-Label zeigt current/max numerisch",
		hp_label.text.contains("2") and hp_label.text.contains("5"), hp_label.text)
	# HP-Bar ist das erste Kind der HP-Zeile (HBox mit Bar + Label).
	var hp_bar := hp_label.get_parent().get_child(0) as ProgressBar
	check("HP-Bar vorhanden und gefuettert", hp_bar != null
		and hp_bar.max_value == 5.0 and hp_bar.value == 2.0)
	check("Stamina 62 uebernommen", is_equal_approx(stamina.value, 62.0))
	check("Geruest: Weapon+Armor+Guard sichtbar",
		gear.visible and gear.text.contains("Vibroklinge")
		and gear.text.contains("Lab-Panzerung") and gear.text.contains("Guard"))
	check("Zone/Wachen/Splitter gefuettert",
		zone.visible and zone.text.contains("Labor")
		and guards.text.contains("3") and guards.text.contains("9")
		and shards.text.contains("7"))
	check("Prompt+Feedback+Objective sichtbar",
		prompt.visible and feedback.visible and objective.visible)
	check("Save-Warnung und Hilfe versteckt", not save_warn.visible and not help_panel.visible)

	# Panelbudget 310x115 (bei logischem 1280x720-Fenster).
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	var ps: Vector2 = panel.size
	check("Top-left Panel <= 310x115", ps.x <= 310.0 and ps.y <= 115.0,
		"panel=%.0fx%.0f" % [ps.x, ps.y])
	check("Panel-Margin 20", panel.position == Vector2(20, 20))

	# --- 3) Clamping / zerzauste Werte ----------------------------------------------
	hud.update_state({"hp": -3, "max_hp": 0, "stamina": 250.0})
	await process_frame
	check("max_hp=0: Balken endlich, Label zeigt 0", is_finite(stamina.value)
		and hp_label.text.contains("0"), hp_label.text)
	check("hp=-3 -> Bar bei 0 (nicht negativ)", hp_bar != null and hp_bar.value == 0.0)
	check("HP-Bar Wert geclampt 0..max", hp_bar != null and hp_bar.value >= 0.0
		and hp_bar.value <= hp_bar.max_value and is_finite(hp_bar.max_value)
		and hp_bar.max_value >= 1.0, "val=%.1f max=%.1f" % [hp_bar.value, hp_bar.max_value])
	check("stamina=250 -> 100", is_equal_approx(stamina.value, 100.0))
	hud.update_state({"hp": 99, "max_hp": 5, "stamina": -10.0})
	await process_frame
	check("hp=99 bei max 5 -> Bar <= max", hp_bar.value <= hp_bar.max_value)
	check("stamina=-10 -> 0", is_equal_approx(stamina.value, 0.0))

	# --- 4) Defaults bei fehlenden Keys --------------------------------------------
	hud.update_state({})
	await process_frame
	check("leeres Dict: alles sichtbar-stabil, keine Fehler",
		hp_label.text != "" and guards.visible and shards.visible)
	check("leerer Prompt/Feedback versteckt", not prompt.visible and not feedback.visible)
	check("ohne Waffe/Ruestung: Gear-Zeile versteckt", not gear.visible)

	# --- 5) Schild-Toggle -------------------------------------------------------------
	hud.update_state({"shield_unlocked": false})
	await process_frame
	var has_guard := gear.text.contains("Guard")
	check("locked shield hides stamina bar",not stamina.visible)
	hud.update_state({"shield_unlocked": true})
	await process_frame
	check("unlocked shield shows stamina bar",stamina.visible)
	check("Schild-Toggle aendert Gear-Zeile", (not has_guard) and gear.text.contains("Guard"))

	# --- 6) Save-Warnung: sichtbar und NICHT hinter feedback -------------------------
	hud.update_state({"feedback": "", "save_error": true})
	await process_frame
	check("save_error: Warnung sichtbar, auch ohne Feedback", save_warn.visible)
	hud.update_state({"feedback": "Etwas", "save_error": true})
	await process_frame
	check("save_error bleibt sichtbar neben Feedback", save_warn.visible and feedback.visible)
	var sr := save_warn.get_global_rect()
	var fr := feedback.get_global_rect()
	check("Save-Warnung eigene Zeile (kein Rect-Ueberlapp mit Feedback)",
		not sr.intersects(fr.grow(-2)), "warn=%s fb=%s" % [str(sr), str(fr)])

	# --- 7) Hilfe nur bei help_visible; Footer F1 immer; kein F5 -----------------------
	var text_all := _visible_text(hud)
	check("F1-Hilfe-Footer immer sichtbar", text_all.contains("F1"))
	check("kein F5/Save-Reset im Normal-HUD", not text_all.contains("F5"))
	hud.update_state({"help_visible": true})
	await process_frame
	check("help_visible=true: HelpPanel sichtbar", help_panel.visible)
	var ht := _visible_text(help_panel)
	check("Hilfe deckt Steuerung ab (A/D, Space, J, Shift, E, Guard)",
		ht.contains("A/D") and ht.contains("Space") and ht.contains("J")
		and ht.contains("Shift") and ht.contains("E") and ht.contains("Guard"))
	hud.update_state({"help_visible": false})
	await process_frame
	check("help_visible=false: HelpPanel weg", not help_panel.visible)

	# --- 8) 100x update_state ohne Knotenwachstum ------------------------------------
	for i in 100:
		hud.update_state({"hp": i % 6, "max_hp": 5, "prompt": "[E] %d" % i,
			"save_error": i % 3 == 0, "help_visible": i % 5 == 0})
	await process_frame
	var nodes1 := _controls(hud).size()
	check("100x update_state: kein Knotenwachstum", nodes1 == nodes0,
		"before=%d after=%d" % [nodes0, nodes1])

	# --- 9) Layout 960x540 ohne Ueberlappung -----------------------------------------
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	var r_tl: Rect2 = panel.get_global_rect()
	var r_tr := zone.get_global_rect().merge(guards.get_global_rect()).merge(shards.get_global_rect())
	check("960x540: oben-links vs oben-rechts ohne Ueberlappung",
		not r_tl.intersects(r_tr), "tl=%s tr=%s" % [str(r_tl), str(r_tr)])
	var r_bot := prompt.get_global_rect().merge(objective.get_global_rect())
	check("960x540: unten-Bereich bleibt im Viewport",
		r_bot.end.y <= 540.0 + 1.0 and r_bot.position.y >= 0.0, "bot=%s" % str(r_bot))

	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	var r_tl2: Rect2 = panel.get_global_rect()
	var r_tr2 := zone.get_global_rect()
	check("1920x1080: Panel bleibt links, Zone rechts",
		r_tl2.end.x < r_tr2.position.x, "tl_end=%.0f tr_x=%.0f" % [r_tl2.end.x, r_tr2.position.x])

	print("H25 SUMMARY checks=%d failures=%d" % [checks, failures])
	hud.free()
	quit(1 if failures else 0)
