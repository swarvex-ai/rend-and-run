extends Control
## H30 — Pause-Menue (eigenstaendiges Control-Modul).
## Signale resume_requested / restart_requested / quit_requested; Codex
## verdrahtet Esc/gamepadStart, SceneTree-Pause und das geladene
## Checkpoint-Neuladen. Das Modul fuehrt NIEMALS selbst einen Engine-Quit,
## Szenen-Reload oder Pause-Befehl aus und betreibt kein Save-IO — es
## entscheidet nur over UI-Zustand
## und emittiert Signale exakt einmal pro Aktivierung.
##
## process_mode ist fest ALWAYS, damit das Menue bei pausiertem Baum
## weiterbedient werden kann. Initialet versteckt; oeffnen ueber open_menu(),
## schliessen ueber close_menu(). Keine externen Assets, keine Polling-Loop,
## ESC wird NICHT im Modul behandelt.
##
## Farbpalette folgt modules/ui/combat_hud.gd (Off-White / blasses Cyan /
## gedaempftes Kupfer). Schriftgroessen >= 18 px.

signal resume_requested
signal restart_requested
signal quit_requested

const COL_BG := Color(0.02, 0.03, 0.04, 0.66)        # Backdrop, dunkel translucent
const COL_PANEL := Color(0.07, 0.08, 0.10, 0.92)     # wie HUD-Panel, deckender
const COL_TEXT := Color(0.93, 0.90, 0.84)            # warmes Off-White
const COL_DIM := Color(0.93, 0.90, 0.84, 0.62)       # Sekundaertext
const COL_CYAN := Color(0.55, 0.82, 0.85)            # Focus (blasses Zyan)
const COL_COPPER := Color(0.82, 0.55, 0.22)          # Akzent (Amber/Kupfer)
const COL_BTN := Color(0.12, 0.14, 0.17, 0.95)
const COL_BTN_HOVER := Color(0.18, 0.22, 0.26, 1.0)
const COL_BTN_DOWN := Color(0.10, 0.11, 0.13, 1.0)

var _btn_resume: Button
var _btn_restart: Button
var _btn_quit: Button
var _btn_back: Button
var _btn_reload: Button
var _main_box: VBoxContainer
var _confirm_box: VBoxContainer
var _confirm_label: Label


func _init() -> void:
	# Aufbau in _init: find_child/API gelten schon vor dem Baumeintritt,
	# falls Codex erst open_menu() und dann add_child() aufruft.
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "PauseMenu"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Fullrect: Anker UND Offsets (Anker allein liessen rechte/untere Kante
	# ausserhalb des CanvasLayer-Camas wandern — H25-Lektion).
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
	# schmales, zentriertes Panel (360 px) — passt von 960x540 bis 1920x1080
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -180.0
	panel.offset_right = 180.0
	panel.offset_top = -160.0
	panel.offset_bottom = 160.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var psb := StyleBoxFlat.new()
	psb.bg_color = COL_PANEL
	psb.border_color = Color(COL_COPPER.r, COL_COPPER.g, COL_COPPER.b, 0.8)
	psb.set_border_width_all(2)
	psb.set_content_margin_all(20.0)
	panel.add_theme_stylebox_override("panel", psb)
	add_child(panel)

	var col := VBoxContainer.new()
	col.name = "Column"
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	col.add_child(_mk_label("TitleLabel", "REND&RUN", 30, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_mk_label("PauseLabel", "PAUSE", 20, COL_CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_mk_label("InfoLabel", "Ausrüstung und gespeicherter Fortschritt\nbleiben erhalten.", 18, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_mk_spacer(6))

	_main_box = VBoxContainer.new()
	_main_box.name = "MainBox"
	_main_box.add_theme_constant_override("separation", 10)
	col.add_child(_main_box)
	_btn_resume = _mk_button("BtnResume", "Weiter")
	_btn_restart = _mk_button("BtnRestart", "Zum Kontrollpunkt")
	_btn_quit = _mk_button("BtnQuit", "Spiel beenden")
	_main_box.add_child(_btn_resume)
	_main_box.add_child(_btn_restart)
	_main_box.add_child(_btn_quit)

	_confirm_box = VBoxContainer.new()
	_confirm_box.name = "ConfirmBox"
	_confirm_box.add_theme_constant_override("separation", 10)
	_confirm_box.visible = false
	col.add_child(_confirm_box)
	_confirm_label = _mk_label("ConfirmLabel", "Wirklich zum letzten gespeicherten\nKontrollpunkt zurück?", 18, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_confirm_box.add_child(_confirm_label)
	_btn_back = _mk_button("BtnBack", "Zurück")
	_btn_reload = _mk_button("BtnReload", "Neu laden")
	_confirm_box.add_child(_btn_back)
	_confirm_box.add_child(_btn_reload)

	_btn_resume.pressed.connect(_on_resume)
	_btn_restart.pressed.connect(_on_restart)
	_btn_quit.pressed.connect(_on_quit)
	_btn_back.pressed.connect(_on_back)
	_btn_reload.pressed.connect(_on_reload)


func open_menu() -> void:
	# Hauptansicht wiederherstellen (offener Bestaetigungsdialog wird verworfen)
	_show_main()
	visible = true
	if _btn_resume.is_inside_tree():
		_btn_resume.grab_focus()


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


func _on_resume() -> void:
	resume_requested.emit()


func _on_restart() -> void:
	_show_confirm()
	if _btn_reload.is_inside_tree():
		_btn_reload.grab_focus()


func _on_back() -> void:
	_show_main()
	if _btn_restart.is_inside_tree():
		_btn_restart.grab_focus()


func _on_quit() -> void:
	quit_requested.emit()


func _on_reload() -> void:
	restart_requested.emit()


func _mk_label(lbl_name: String, txt: String, size: int, color: Color, align: int) -> Label:
	var l := Label.new()
	l.name = lbl_name
	l.text = txt
	l.horizontal_alignment = align
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
	b.custom_minimum_size = Vector2(300, 46)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", COL_TEXT)
	b.add_theme_color_override("font_hover_color", COL_CYAN)
	b.add_theme_color_override("font_pressed_color", COL_CYAN)
	b.add_theme_color_override("font_focus_color", COL_CYAN)
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
	# sichtbarer Fokus: markanter Cyan-Rahmen (Tastatur/Controller-Navigation)
	var fb := nb.duplicate() as StyleBoxFlat
	fb.draw_center = false
	fb.set_border_width_all(3)
	fb.border_color = COL_CYAN
	b.add_theme_stylebox_override("focus", fb)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	return b
