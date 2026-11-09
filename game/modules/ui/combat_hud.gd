extends Control
# H25 — Kompaktes Combat-HUD (Ziel: res://modules/ui/combat_hud.gd).
# Vertrag: outputs/worker_contracts/H25-combat-hud.txt (Codex, 06.10.2026). Basis 5cebdd1.
# - Control ohne class_name; fuellt den Parent-Viewport via Anchors.
# - mouse_filter IGNORE auf ALLEN Controls — kein Inputverbrauch.
# - Oeffentliche API: update_state(state: Dictionary) -> void; aufrufbar nach
#   _ready; KEIN Per-Frame-Polling; Controls werden EINMAL konstruiert —
#   Updates setzen nur Texte/Balken/Sichtbarkeiten, erzeugen nie neue Kinder.
# - Fehlende Dictionary-Keys nutzen sinnvolle Defaults.
# - Keys: hp, max_hp, stamina(0..100), shield_unlocked, weapon_name, armor_name,
#   shards, guards_defeated, guards_total, zone, objective, prompt, feedback,
#   save_error, help_visible.
# - Look: dunkle translucente Panels, warmes Off-White, gedaempft amber HP,
#   blasses Zyan Stamina; keine dicken Raender/Glow; Spielmitte bleibt frei.
#   Nur eingebaute Fonts/StyleBoxFlat; Fonts >= 16 px sekundar, 18 px main.
# - Help-Panel NUR bei help_visible; Footer 'F1 Hilfe' immer; NIE F5 Save-Reset.

const UI_TEXT = preload("res://data/ui_texts.gd")

const COLOR_PANEL := Color(0.07, 0.08, 0.10, 0.62)       # dunkel, translucent
const COLOR_TEXT := Color(0.93, 0.90, 0.84)              # warmes Off-White
const COLOR_DIM := Color(0.93, 0.90, 0.84, 0.62)         # Sekundaer
const COLOR_HP := Color(0.82, 0.55, 0.22)                # gedaempftes Amber
const COLOR_HP_BG := Color(0.16, 0.13, 0.09, 0.75)
const COLOR_STAMINA := Color(0.55, 0.82, 0.85)           # blasses Zyan
const COLOR_STAMINA_BG := Color(0.09, 0.15, 0.17, 0.75)
const COLOR_WARN := Color(0.90, 0.45, 0.30)              # Save-Warnung

const FONT_MAIN := 18
const FONT_SUB := 16

# Referenzen auf die EINMAL gebauten Controls.
var _hp_label: Label
var _hp_bar: ProgressBar
var _stamina_bar: ProgressBar
var _gear_label: Label
var _zone_label: Label
var _guards_label: Label
var _shards_label: Label
var _objective_label: Label
var _feedback_label: Label
var _prompt_label: Label
var _save_warn_label: Label
var _help_panel: PanelContainer
var _footer_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	# Neutraler Grundzustand, bis der Aufrufer Zustand liefert.
	update_state({})
	resized.connect(_layout_feedback)
	_layout_feedback()


# ---------------------------------------------------------------------------
# Oeffentliche API

func update_state(state: Dictionary) -> void:
	var hp := int(state.get("hp", 3))
	var max_hp := maxi(int(state.get("max_hp", 3)), 0)
	# Clamping: endliche, sinnvolle Anzeige auch bei Zero/Uberlauf.
	var shown_max := maxi(max_hp, 1)
	hp = clampi(hp, 0, max_hp)
	_hp_bar.max_value = shown_max
	_hp_bar.value = hp
	_hp_label.text = "HP %d/%d" % [hp, max_hp]

	var stamina := float(state.get("stamina", 100.0))
	stamina = clampf(stamina, 0.0, 100.0) if is_finite(stamina) else 0.0
	_stamina_bar.value = stamina
	_stamina_bar.visible = bool(state.get("shield_unlocked", false))

	var weapon := str(state.get("weapon_name", ""))
	var armor := str(state.get("armor_name", ""))
	var gear_parts: Array[String] = []
	if weapon != "":
		gear_parts.append(weapon)
	if armor != "":
		gear_parts.append(armor)
	if bool(state.get("shield_unlocked", false)):
		gear_parts.append("Guard")
	_gear_label.text = " · ".join(gear_parts)
	_gear_label.visible = not gear_parts.is_empty()

	_zone_label.text = str(state.get("zone", ""))
	_zone_label.visible = _zone_label.text != ""
	_guards_label.text = UI_TEXT.t("hud_guards") % [int(state.get("guards_defeated", 0)), int(state.get("guards_total", 0))]
	_shards_label.text = UI_TEXT.t("hud_shards") % int(state.get("shards", 0))
	if state.get("servo_unlocked",false):_shards_label.text += UI_TEXT.t("hud_servo_suffix")%int(state.get("servo",0))

	var objective := str(state.get("objective", ""))
	_objective_label.text = objective
	_objective_label.visible = objective != ""

	# Prompt unten-Mitte: nur bei nicht-leerem Text sichtbar (kein Dauerblocker).
	var prompt := str(state.get("prompt", ""))
	_prompt_label.text = prompt
	_prompt_label.visible = prompt != ""

	# Feedback darueber; Lifetime liegt beim Aufrufer (leer = versteckt).
	var feedback := str(state.get("feedback", ""))
	_feedback_label.text = feedback
	_feedback_label.visible = feedback != ""
	_layout_feedback()

	# Save-Fehler: eigene explizite Warnung, NIE hinter feedback versteckt.
	var show_save_warn := bool(state.get("save_error", false))
	_save_warn_label.visible = show_save_warn

	_help_panel.visible = bool(state.get("help_visible", false))


# ---------------------------------------------------------------------------
# Aufbau (einmalig)

func _build() -> void:
	_build_top_left()
	_build_top_right()
	_build_bottom()


func _panel_style(border: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_corner_radius_all(border)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _make_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_top_left() -> void:
	# Kompaktpanel max 310x115, Margin 20, oben-links verankert.
	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.position = Vector2(20, 20)
	# Inhaltsshrink: Panel bleibt so klein wie sein Inhalt (Budget 310x115,
	# Test misst die reale Groesse nach Layout).
	panel.custom_minimum_size.x = 300
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(panel)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)

	var name_label := _make_label(FONT_MAIN, COLOR_TEXT)
	name_label.text = "REND"
	col.add_child(name_label)

	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override("separation", 8)
	col.add_child(hp_row)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(120, 10)
	_hp_bar.show_percentage = false
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.step = 1
	_hp_bar.add_theme_stylebox_override("background", _bar_bg(COLOR_HP_BG))
	_hp_bar.add_theme_stylebox_override("fill", _bar_fill(COLOR_HP))
	hp_row.add_child(_hp_bar)

	_hp_label = _make_label(FONT_MAIN, COLOR_TEXT)
	_hp_label.name = "HpLabel"
	hp_row.add_child(_hp_label)

	# Duennere Stamina-Leiste (Zyan), ohne Extra-Text.
	_stamina_bar = ProgressBar.new()
	_stamina_bar.name = "StaminaBar"
	_stamina_bar.custom_minimum_size = Vector2(150, 5)
	_stamina_bar.max_value = 100
	_stamina_bar.show_percentage = false
	_stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_bar.add_theme_stylebox_override("background", _bar_bg(COLOR_STAMINA_BG))
	_stamina_bar.add_theme_stylebox_override("fill", _bar_fill(COLOR_STAMINA))
	col.add_child(_stamina_bar)

	_gear_label = _make_label(FONT_SUB, COLOR_DIM)
	_gear_label.name = "GearLabel"
	_gear_label.custom_minimum_size.x = 280
	_gear_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_gear_label)


func _build_top_right() -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	# Rechts oben verankert mit Margin 20.
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -240
	box.offset_top = 20
	box.offset_right = -20
	box.offset_bottom = 110

	_zone_label = _make_label(FONT_MAIN, COLOR_TEXT)
	_zone_label.name = "ZoneLabel"
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_zone_label)

	_guards_label = _make_label(FONT_SUB, COLOR_DIM)
	_guards_label.name = "GuardsLabel"
	_guards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_guards_label)

	_shards_label = _make_label(FONT_SUB, COLOR_DIM)
	_shards_label.name = "ShardsLabel"
	_shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_shards_label)
	add_child(box)


func _build_bottom() -> void:
	# Objective klein, unten-links.
	_objective_label = _make_label(FONT_SUB, COLOR_DIM)
	_objective_label.name = "ObjectiveLabel"
	_objective_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_objective_label.offset_left = 20
	_objective_label.offset_top = -46
	_objective_label.offset_right = 420
	_objective_label.offset_bottom = -20
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_objective_label)

	# Zentrale untere Spalte (Feedback ueber Prompt), schmal — Spielmitte frei.
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	col.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	col.offset_left = -280
	col.offset_right = 280
	col.offset_top = -140
	col.offset_bottom = -18
	add_child(col)

	# Wide viewports have room between status and counters. Keep messages there
	# so the factory windows stay visible; narrow windows retain a separate lane.
	_feedback_label = _make_label(FONT_SUB, COLOR_HP)
	_feedback_label.name = "FeedbackLabel"
	var feedback_back := StyleBoxFlat.new()
	feedback_back.bg_color = Color(0.07, 0.08, 0.10, 0.82)
	feedback_back.set_corner_radius_all(4)
	feedback_back.content_margin_left = 10
	feedback_back.content_margin_right = 10
	feedback_back.content_margin_top = 6
	feedback_back.content_margin_bottom = 6
	_feedback_label.add_theme_stylebox_override("normal", feedback_back)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.anchor_left = 0.5
	_feedback_label.anchor_right = 0.5
	_feedback_label.offset_left = 0.0
	_feedback_label.offset_right = 0.0
	_feedback_label.offset_top = 116.0
	_feedback_label.offset_bottom = 116.0
	_feedback_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_feedback_label.visible = false
	add_child(_feedback_label)

	_prompt_label = _make_label(FONT_MAIN, COLOR_TEXT)
	_prompt_label.name = "PromptLabel"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.visible = false
	col.add_child(_prompt_label)

	# Save-Warnung: eigene kleine Zeile, direkt sichtbar, nicht hinter feedback.
	_save_warn_label = _make_label(FONT_SUB, COLOR_WARN)
	_save_warn_label.name = "SaveWarn"
	_save_warn_label.text = UI_TEXT.t("hud_save_failed")
	_save_warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_warn_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_save_warn_label.offset_left = -280
	_save_warn_label.offset_right = 280
	_save_warn_label.offset_top = -170
	_save_warn_label.offset_bottom = -146
	_save_warn_label.visible = false
	add_child(_save_warn_label)

	# Footer 'F1 Hilfe' immer, dezent unten-rechts.
	var footer := _make_label(FONT_SUB, COLOR_DIM)
	_footer_label = footer
	footer.name = "HelpFooter"
	footer.text = UI_TEXT.t("hud_footer_wide")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.offset_left = -460
	footer.offset_top = -30
	footer.offset_right = -20
	footer.offset_bottom = -14
	add_child(footer)

	_build_help_panel()


func _build_help_panel() -> void:
	# Help-Panel: NUR bei help_visible; mittig, aber kompakt und translucent.
	_help_panel = PanelContainer.new()
	_help_panel.name = "HelpPanel"
	_help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_panel.add_theme_stylebox_override("panel", _panel_style(8))
	_help_panel.set_anchors_preset(Control.PRESET_CENTER)
	_help_panel.offset_left = -200
	_help_panel.offset_right = 200
	_help_panel.offset_top = -150
	_help_panel.offset_bottom = 150
	_help_panel.visible = false
	add_child(_help_panel)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	_help_panel.add_child(col)

	var title := _make_label(FONT_MAIN, COLOR_TEXT)
	title.text = UI_TEXT.t("hud_help_title")
	col.add_child(title)

	var rows := [
		"A/D", UI_TEXT.t("hud_help_move"),
		"W/S / ↑↓", UI_TEXT.t("hud_help_depth"),
		"Space", UI_TEXT.t("hud_help_jump"),
		"J / X", UI_TEXT.t("hud_help_attack"),
		"Shift / K / B", UI_TEXT.t("hud_help_dodge"),
		UI_TEXT.t("hud_help_crouch_keys"), UI_TEXT.t("hud_help_crouch"),
		"E / Y", UI_TEXT.t("hud_help_interact"),
		"L / RMB / LB", "Guard",
	]
	for i in range(0, rows.size(), 2):
		var row := _make_label(FONT_SUB, COLOR_DIM)
		row.text = "%s — %s" % [rows[i], rows[i + 1]]
		col.add_child(row)


func _bar_bg(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	return sb


func _bar_fill(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	return sb

func _layout_feedback() -> void:
	var wide := size.x >= 960.0
	var half_width := minf(230.0, (size.x-660.0)*0.5) if wide else minf(336.0, size.x*0.45)
	_feedback_label.offset_left = -half_width
	_feedback_label.offset_right = half_width
	_feedback_label.offset_top = 20.0 if wide else 116.0
	_feedback_label.offset_bottom = _feedback_label.offset_top
	if is_instance_valid(_footer_label):
		_footer_label.text = UI_TEXT.t("hud_footer_wide") if wide else UI_TEXT.t("hud_footer_narrow")
		_footer_label.offset_left = -460.0 if wide else -180.0
