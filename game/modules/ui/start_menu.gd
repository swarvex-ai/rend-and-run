extends Control
## H31 — Start-Menue (eigenstaendiges Control-Modul).
## Signale continue_requested / new_run_requested / quit_requested; Codex
## verdrahtet Titel vor aktivem Spiel, Fortsetzen der gespeicherten Route und
## die bestaetigte neue Runde inkl. Save-Handling. Das Modul fuehrt NIEMALS
## selbst einen Engine-Quit, Szenen-Reload oder Pause-Befehl aus und betreibt
## kein Datei-/Save-IO — es entscheidet nur ueber UI-Zustand und emittiert
## Signale exakt einmal pro Aktivierung.
##
## API: open_menu(has_save: bool) / close_menu(). Initialet versteckt.
## process_mode fest ALWAYS (Funktion auch bei gepausetem Baum).
## Ohne Save: Fortsetzen deaktiviert UND nicht fokussierbar, Fokus auf Neue
## Runde, Neue Runde emittiert sofort. Mit Save: Fokus auf Fortsetzen, Neue
## Runde oeffnet ausdrueckliche In-Panel-Bestaetigung; new_run_requested erst
## nach Bestaetigung. Erneutes Oeffnen setzt die Bestaetigung zurueck.
##
## Optik folgt modules/ui/pause_menu.gd / combat_hud.gd (dunkles Panel,
## Off-White / blasses Cyan / Kupfer-Rand). Keine externen Fonts/Assets, kein
## Per-Frame-Werk (kein _process). Deutsche Umlaute im Text.

signal continue_requested
signal new_run_requested
signal quit_requested

const COL_BG := Color(0.02, 0.03, 0.04, 0.78)        # Backdrop, dunkel translucent
const COL_PANEL := Color(0.07, 0.08, 0.10, 0.94)     # wie HUD-Panel
const COL_TEXT := Color(0.93, 0.90, 0.84)            # warmes Off-White
const COL_DIM := Color(0.93, 0.90, 0.84, 0.62)       # Sekundaertext
const COL_CYAN := Color(0.55, 0.82, 0.85)            # Focus/Akzent (blasses Zyan)
const COL_COPPER := Color(0.82, 0.55, 0.22)          # randiger Akzent
const COL_BTN := Color(0.12, 0.14, 0.17, 0.95)
const COL_BTN_HOVER := Color(0.18, 0.22, 0.26, 1.0)
const COL_BTN_DOWN := Color(0.10, 0.11, 0.13, 1.0)
const COL_DISABLED_TEXT := Color(0.93, 0.90, 0.84, 0.32)

var _has_save := false
var _btn_continue: Button
var _btn_new_run: Button
var _btn_quit: Button
var _btn_back: Button
var _btn_confirm_new: Button
var _main_box: VBoxContainer
var _confirm_box: VBoxContainer


func _init() -> void:
	# Aufbau in _init: find_child/API gelten schon vor dem Baumeintritt.
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "StartMenu"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Fullrect: Anker UND Offsets (H25-Lektion).
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = COL_BG
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP   # kein Klick-Through
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	# ruhiges, zentriertes Startpanel (420 px breit) — 960x540..1920x1080
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -210.0
	panel.offset_right = 210.0
	panel.offset_top = -190.0
	panel.offset_bottom = 190.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var psb := StyleBoxFlat.new()
	psb.bg_color = COL_PANEL
	psb.border_color = Color(COL_COPPER.r, COL_COPPER.g, COL_COPPER.b, 0.8)
	psb.set_border_width_all(2)
	psb.set_content_margin_all(24.0)
	panel.add_theme_stylebox_override("panel", psb)
	add_child(panel)

	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	# Titel ohne redundante "REND"-Untertitel
	col.add_child(_mk_label("TitleLabel", "REND&RUN", 40, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_mk_label("SectorLabel", "Laborsektor 01", 18, COL_CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_mk_spacer(8))

	_main_box = VBoxContainer.new()
	_main_box.name = "MainBox"
	_main_box.add_theme_constant_override("separation", 10)
	col.add_child(_main_box)
	_btn_continue = _mk_button("BtnContinue", "Fortsetzen")
	_btn_new_run = _mk_button("BtnNewRun", "Neue Runde")
	_btn_quit = _mk_button("BtnQuit", "Beenden")
	_main_box.add_child(_btn_continue)
	_main_box.add_child(_btn_new_run)
	_main_box.add_child(_btn_quit)

	_confirm_box = VBoxContainer.new()
	_confirm_box.name = "ConfirmBox"
	_confirm_box.add_theme_constant_override("separation", 10)
	_confirm_box.visible = false
	col.add_child(_confirm_box)
	_confirm_box.add_child(_mk_label("ConfirmLabel",
		"Neue Runde starten? Der gespeicherte\nFortschritt dieser Runde wird ersetzt.",
		18, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	_btn_back = _mk_button("BtnBack", "Zurück")
	_btn_confirm_new = _mk_button("BtnConfirmNewRun", "Neue Runde starten")
	_confirm_box.add_child(_btn_back)
	_confirm_box.add_child(_btn_confirm_new)

	col.add_child(_mk_spacer(6))
	# kleine Fusszeile: Steuerungs-Hinweis, keine grosse Spielhilfe
	col.add_child(_mk_label("FooterLabel",
		"A/D Bewegen · Leertaste Springen · J Angriff · Esc Pause",
		18, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	_btn_continue.pressed.connect(_on_continue)
	_btn_new_run.pressed.connect(_on_new_run)
	_btn_quit.pressed.connect(_on_quit)
	_btn_back.pressed.connect(_on_back)
	_btn_confirm_new.pressed.connect(_on_confirm_new_run)


func open_menu(has_save: bool) -> void:
	_has_save = has_save
	_show_main()
	_btn_continue.disabled = not has_save
	# ohne Save auch ohne Fokus-Reihenfolge erreichbar? Nein: deactivated +
	# nicht fokussierbar, damit Tastatur-/Stick-Navigation direkt bei Neue Runde beginnt.
	_btn_continue.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	visible = true
	var first := _btn_continue if has_save else _btn_new_run
	if first.is_inside_tree():
		first.grab_focus()


func close_menu() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _show_main() -> void:
	_main_box.visible = true
	_confirm_box.visible = false


func _show_confirm() -> void:
	_main_box.visible = false
	_confirm_box.visible = true


func _on_continue() -> void:
	continue_requested.emit()


func _on_new_run() -> void:
	if _has_save:
		# ausdrueckliche Bestaetigung noetig — kein Signal hier
		_show_confirm()
		if _btn_confirm_new.is_inside_tree():
			_btn_confirm_new.grab_focus()
	else:
		new_run_requested.emit()


func _on_back() -> void:
	_show_main()
	if _btn_new_run.is_inside_tree():
		_btn_new_run.grab_focus()


func _on_confirm_new_run() -> void:
	new_run_requested.emit()


func _on_quit() -> void:
	quit_requested.emit()


func _mk_label(lbl_name: String, txt: String, size: int, color: Color, align: int) -> Label:
	var l := Label.new()
	l.name = lbl_name
	l.text = txt
	l.horizontal_alignment = align
	# Autowrap: langer Text (Fusszeile/Bestaetigung) bricht sauber inside Panel
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _mk_spacer(h: float) -> Control:
	var s := Control.new()
	s.name = "Spacer"
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _mk_button(btn_name: String, txt: String) -> Button:
	var b := Button.new()
	b.name = btn_name
	b.text = txt
	b.custom_minimum_size = Vector2(340, 46)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", COL_TEXT)
	b.add_theme_color_override("font_hover_color", COL_CYAN)
	b.add_theme_color_override("font_pressed_color", COL_CYAN)
	b.add_theme_color_override("font_focus_color", COL_CYAN)
	b.add_theme_color_override("font_disabled_color", COL_DISABLED_TEXT)
	var nb := StyleBoxFlat.new()
	nb.bg_color = COL_BTN
	nb.set_corner_radius_all(4)
	nb.set_border_width_all(1)
	nb.border_color = Color(0.3, 0.33, 0.36)
	nb.content_margin_left = 14.0
	nb.content_margin_right = 14.0
	b.add_theme_stylebox_override("normal", nb)
	var hb := nb.duplicate() as StyleBoxFlat
	hb.bg_color = COL_BTN_HOVER
	hb.border_color = COL_CYAN
	b.add_theme_stylebox_override("hover", hb)
	var pb := nb.duplicate() as StyleBoxFlat
	pb.bg_color = COL_BTN_DOWN
	pb.border_color = COL_CYAN
	b.add_theme_stylebox_override("pressed", pb)
	# kontrastreicher aktiver Fokus: 3 px Cyan-Rahmen
	var fb := nb.duplicate() as StyleBoxFlat
	fb.draw_center = false
	fb.set_border_width_all(3)
	fb.border_color = COL_CYAN
	b.add_theme_stylebox_override("focus", fb)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	return b
