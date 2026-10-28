extends Control
## H32 — Sektorabschluss (eigenstaendiges Summary-Control).
## Codex ruft show_summary(state) genau einmal beim Erreichen/Oeffnen des
## Exits auf und uebergibt die ECHT gemessenen Werte. Das Modul fuihrt NIEMALS
## selbst Pause/Reload/Quit/FileIO aus und verspricht kein naechstes Level und
## keine Belohnungen — es zeigt Werte und emittiert explore_requested oder
## title_requested (letzteres bei Savefehler erst nach ausdruecklicher
## In-Panel-Bestaetigung).
##
## state-Schluessel (von Codex gefuellt):
##   guards_defeated:int, guards_total:int, shards:int,
##   weapon_name:String, armor_name:String, save_ok:bool
##
## API: show_summary(state: Dictionary) / close_summary().
## process_mode fest ALWAYS; initialet versteckt; Fullrect anchors+offsets;
## Backdrop blockt Klicks; kein _process; keine externen Ressourcen.

signal explore_requested
signal title_requested

const COL_BG := Color(0.02, 0.03, 0.04, 0.82)
const COL_PANEL := Color(0.07, 0.08, 0.10, 0.95)
const COL_TEXT := Color(0.93, 0.90, 0.84)
const COL_DIM := Color(0.93, 0.90, 0.84, 0.62)
const COL_CYAN := Color(0.55, 0.82, 0.85)
const COL_COPPER := Color(0.82, 0.55, 0.22)
const COL_OK := Color(0.60, 0.84, 0.62)             # gedecktes Gruen fuer Speichern OK
const COL_WARN := Color(0.90, 0.68, 0.35)           # Kupfergelb fuer Speichern fehlgeschlagen
const COL_BTN := Color(0.12, 0.14, 0.17, 0.95)

var _save_ok := true
var _val_guards: Label
var _val_shards: Label
var _val_weapon: Label
var _val_armor: Label
var _save_label: Label
var _btn_explore: Button
var _btn_title: Button
var _btn_back: Button
var _btn_leave: Button
var _main_box: VBoxContainer
var _confirm_box: VBoxContainer


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "SectorComplete"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -220.0
	panel.offset_right = 220.0
	panel.offset_top = -215.0
	panel.offset_bottom = 215.0
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
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	col.add_child(_mk_label("TitleLabel", "SEKTOR GESICHERT", 34, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_mk_label("SectorLabel", "Laborsektor 01", 18, COL_CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_mk_spacer(6))

	_main_box = VBoxContainer.new()
	_main_box.name = "MainBox"
	_main_box.add_theme_constant_override("separation", 8)
	col.add_child(_main_box)
	_val_guards = _mk_value_row(_main_box, "Wachen", "0 / 0")
	_val_shards = _mk_value_row(_main_box, "Splitter", "0")
	_val_weapon = _mk_value_row(_main_box, "Waffe", "—")
	_val_armor = _mk_value_row(_main_box, "Rüstung", "—")
	col.add_child(_mk_spacer(4))
	_save_label = _mk_label("SaveStatus", "", 18, COL_OK, HORIZONTAL_ALIGNMENT_LEFT)
	col.add_child(_save_label)
	col.add_child(_mk_spacer(6))
	_btn_explore = _mk_button("BtnExplore", "Weiter erkunden")
	_btn_title = _mk_button("BtnTitle", "Zum Hauptmenü")
	_main_box.add_child(_btn_explore)
	_main_box.add_child(_btn_title)

	_confirm_box = VBoxContainer.new()
	_confirm_box.name = "ConfirmBox"
	_confirm_box.add_theme_constant_override("separation", 8)
	_confirm_box.visible = false
	col.add_child(_confirm_box)
	_confirm_box.add_child(_mk_label("ConfirmLabel",
		"Trotzdem zum Hauptmenü?\nUngespeicherter Fortschritt geht verloren.",
		18, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	_btn_back = _mk_button("BtnBack", "Zurück")
	_btn_leave = _mk_button("BtnLeave", "Verlassen")
	_confirm_box.add_child(_btn_back)
	_confirm_box.add_child(_btn_leave)

	_btn_explore.pressed.connect(_on_explore)
	_btn_title.pressed.connect(_on_title)
	_btn_back.pressed.connect(_on_back)
	_btn_leave.pressed.connect(_on_leave)


func show_summary(state: Dictionary) -> void:
	# Werte 1:1 aus dem Staat — nichts dazuerdacht, nichts beschoenigt.
	_save_ok = bool(state.get("save_ok", false))
	_val_guards.text = "%d / %d" % [int(state.get("guards_defeated", 0)), int(state.get("guards_total", 0))]
	_val_shards.text = str(int(state.get("shards", 0)))
	var w := str(state.get("weapon_name", ""))
	var a := str(state.get("armor_name", ""))
	_val_weapon.text = w if w != "" else "— keine —"
	_val_armor.text = a if a != "" else "— keine —"
	if _save_ok:
		_save_label.text = "Fortschritt gespeichert"
		_save_label.add_theme_color_override("font_color", COL_OK)
	else:
		_save_label.text = "Speichern fehlgeschlagen — Fortschritt nur in dieser Sitzung."
		_save_label.add_theme_color_override("font_color", COL_WARN)
	_show_main()
	visible = true
	if _btn_explore.is_inside_tree():
		_btn_explore.grab_focus()


func close_summary() -> void:
	visible = false


func _show_main() -> void:
	_main_box.visible = true
	_confirm_box.visible = false


func _on_explore() -> void:
	# immer sicheres Signal — auch im Fehlerfall bleibt die Sitzung spielbar
	explore_requested.emit()


func _on_title() -> void:
	if _save_ok:
		title_requested.emit()
	else:
		# verlustfreier Umweg: ausdrueckliche Bestaetigung noetig
		_confirm_box.visible = true
		_main_box.visible = false
		if _btn_leave.is_inside_tree():
			_btn_leave.grab_focus()


func _on_back() -> void:
	_show_main()
	if _btn_explore.is_inside_tree():
		_btn_explore.grab_focus()


func _on_leave() -> void:
	title_requested.emit()


func _mk_value_row(parent: VBoxContainer, key: String, initial: String) -> Label:
	var row := HBoxContainer.new()
	row.name = "Row_" + key
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var k := _mk_label("Key_" + key, key, 18, COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	k.custom_minimum_size = Vector2(96, 0)
	row.add_child(k)
	var v := _mk_label("Val_" + key, initial, 18, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	return v


func _mk_label(lbl_name: String, txt: String, size: int, color: Color, align: int) -> Label:
	var l := Label.new()
	l.name = lbl_name
	l.text = txt
	l.horizontal_alignment = align
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
	b.custom_minimum_size = Vector2(356, 46)
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
	hb.bg_color = Color(0.18, 0.22, 0.26, 1.0)
	hb.border_color = COL_CYAN
	b.add_theme_stylebox_override("hover", hb)
	var pb := nb.duplicate() as StyleBoxFlat
	pb.bg_color = Color(0.10, 0.11, 0.13, 1.0)
	pb.border_color = COL_CYAN
	b.add_theme_stylebox_override("pressed", pb)
	var fb := nb.duplicate() as StyleBoxFlat
	fb.draw_center = false
	fb.set_border_width_all(3)
	fb.border_color = COL_CYAN
	b.add_theme_stylebox_override("focus", fb)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	return b
