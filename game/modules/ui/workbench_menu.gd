extends Control
# H69 — Werkbank-Auswahlmenü (isoliertes Deliverable, kein class_name).
# Reine Auswahl-UI: sendet action_requested/close_requested; Kauf, Ausrüsten,
# Save, Pause und Input-Routing (Esc/B) gehören dem Owner.
# Nur eingebaute Controls/StyleBoxen/Fonts. Kein _process-Polling,
# Nodes werden einmal gebaut und nur inhaltlich aktualisiert.
# H68-Lehre: Root-Control unter CanvasLayer kann 0x0 sein — Viewport-Größe
# wird explizit verfolgt (Viewport.size_changed + NOTIFICATION_RESIZED),
# Top-left-Anker statt Full-rect-Anker.

signal action_requested(item_id: String)
signal close_requested

const PREFIX := preload("res://modules/equipment/prefix_ledger.gd")
const ID_STARTER := "robot_arm"
const ID_VIBRO := "reinforced_arm"
const ITEMS := preload("res://modules/equipment/item_catalog.gd")
const VIBRO_COST: int = ITEMS.ITEMS["reinforced_arm"].cost

const COLOR_BACKDROP := Color(0.0, 0.0, 0.0, 0.55)
const COLOR_PANEL := Color(0.075, 0.125, 0.135, 0.96)
const COLOR_COPPER := Color(0.72, 0.47, 0.30)
const COLOR_TEXT := Color(0.88, 0.90, 0.89)
const COLOR_MUTED := Color(0.70, 0.74, 0.73)
const COLOR_BTN := Color(0.105, 0.170, 0.180)
const COLOR_BTN_HOVER := Color(0.145, 0.230, 0.240)
const COLOR_BTN_DISABLED := Color(0.10, 0.13, 0.135, 0.90)

var _trial_unlocked := false
var _trial_ready := false
var _servo := 0
var _trial_defeated := 0
var _bonus_misses := 0
var _servo_owned := false
var _servo_installed := false
var _servo_action: Button
var _servo_info: Label
var _trial_action: Button
var _trial_info: Label
var _shards: int = 0
var _owned: Array[String] = []
var _equipped: String = ID_STARTER
var _feedback: String = ""
var _locked_id: String = ""
var _focus_policy: int = 0  # 0 = Fokus erhalten, 1 = Primäraktion erzwingen
var _view_size: Vector2 = Vector2(640.0, 360.0)
var _viewport: Viewport = null

var _backdrop: ColorRect
var _panel: Panel
var _balance_label: Label
var _starter_info: Label
var _vibro_info: Label
var _starter_action: Button
var _vibro_action: Button
var _btn_close: Button
var _shortage_label: Label
var _feedback_label: Label
var _footer_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_once()
	call_deferred("_wire_viewport")
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and size != _view_size:
		_view_size = size
		_layout()


func open_menu(state: Dictionary) -> void:
	_locked_id = ""
	visible = true
	_focus_policy = 1
	_apply_state(state)


func update_state(state: Dictionary) -> void:
	_locked_id = ""
	_focus_policy = 0
	_apply_state(state)


func close_menu() -> void:
	_locked_id = ""
	visible = false
	if _viewport != null:
		_viewport.gui_release_focus()


func _wire_viewport() -> void:
	_viewport = get_viewport()
	if _viewport != null and not _viewport.size_changed.is_connected(_on_viewport_resized):
		_viewport.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _on_viewport_resized() -> void:
	if _viewport == null:
		return
	var vs: Vector2 = _viewport.get_visible_rect().size
	if vs.x > 0.0 and vs.y > 0.0 and vs != _view_size:
		_view_size = vs
		_layout()


func _apply_state(state: Dictionary) -> void:
	_trial_unlocked=state.get("trial_unlocked",false)
	_trial_ready=state.get("trial_ready",false)
	_servo=int(state.get("servo",0))
	_trial_defeated=int(state.get("trial_defeated",0))
	_bonus_misses=clampi(int(state.get("bonus_misses",0)),0,3)
	_servo_owned=state.get("servo_owned",false)
	_servo_installed=state.get("servo_installed",false)
	_shards = int(state.get("shards", 0))
	var o: Array[String] = []  # Found in the world; never invent ownership.
	for e in (state.get("owned", []) as Array):
		var s: String = str(e)
		if (s == ID_STARTER or s == ID_VIBRO) and not o.has(s):
			o.append(s)
	_owned = o
	_equipped = str(state.get("equipped", ID_STARTER))
	_feedback = str(state.get("feedback", ""))
	_refresh()
	_layout()


func _is_owned(id: String) -> bool:
	return _owned.has(id)


func _primary() -> Button:
	if not _vibro_action.disabled:
		return _vibro_action
	if _servo_action.visible and not _servo_action.disabled:
		return _servo_action
	if _trial_action.visible and not _trial_action.disabled:
		return _trial_action
	if not _starter_action.disabled:
		return _starter_action
	return _btn_close


func _refresh() -> void:
	_balance_label.text = "Splitter: %d · Servo: %d" % [_shards,_servo]
	_trial_action.visible=_trial_unlocked
	_trial_info.visible=_trial_unlocked and _feedback.is_empty()
	_trial_action.disabled=not _trial_unlocked or not _trial_ready
	_trial_action.text="Servoteile bergen · 5 Roboter" if _trial_ready else "Bergung %d/5 — fortsetzen"%_trial_defeated if _trial_defeated<5 else "5/5 besiegt — übrige Teile einsammeln"
	_trial_info.text="12 Splitter + 1 Servo sicher · Extra spätestens in %d %s"%[4-_bonus_misses,"Lauf" if _bonus_misses==3 else "Läufen"] if _trial_ready else "Fortschritt gespeichert · zurück in den Raum"
	_servo_info.visible=_is_owned(ID_VIBRO);_servo_action.visible=_is_owned(ID_VIBRO)
	_servo_info.text=PREFIX.summary()+"\n"+("Modul im Besitz" if _servo_owned else "%d/12 Splitter · %d/2 Servo"%[_shards,_servo])
	_servo_action.text="Abbauen" if _servo_installed else "Anbauen" if _servo_owned else "Herstellen"
	_servo_action.disabled=not _is_owned(ID_VIBRO) or (not _servo_owned and (_shards<12 or _servo<2))
	_feedback_label.text = _feedback
	_feedback_label.visible = _feedback != ""

	if _equipped == ID_STARTER:
		_starter_action.text = "Ausgerüstet"
		_starter_action.disabled = true
	else:
		_starter_action.text = "Ausrüsten"
		_starter_action.disabled = not _is_owned(ID_STARTER) or _locked_id == ID_STARTER

	if _is_owned(ID_VIBRO):
		_shortage_label.visible = false
		if _equipped == ID_VIBRO:
			_vibro_action.text = "Ausgerüstet"
			_vibro_action.disabled = true
		else:
			_vibro_action.text = "Ausrüsten"
			_vibro_action.disabled = _locked_id == ID_VIBRO
	else:
		_vibro_action.text = "Kaufen · %d Splitter" % VIBRO_COST
		var lacking: int = VIBRO_COST - _shards
		_vibro_action.disabled = not _is_owned(ID_STARTER) or lacking > 0 or _locked_id == ID_VIBRO
		_shortage_label.visible = not _is_owned(ID_STARTER) or lacking > 0
		if not _is_owned(ID_STARTER):
			_shortage_label.text = "Zuerst den Humanoidenarm am Start bergen."
		elif lacking > 0:
			_shortage_label.text = "Es fehlen %d Splitter" % lacking

	# Fokus: bei Reopen Primäraktion, sonst existing Button-Fokus erhalten.
	var focus_owner: Control = null
	if _viewport != null:
		focus_owner = _viewport.gui_get_focus_owner()
	var preserve: bool = focus_owner is BaseButton and not focus_owner.disabled \
		and (focus_owner == _starter_action or focus_owner == _vibro_action or focus_owner == _btn_close or focus_owner == _trial_action or focus_owner == _servo_action)
	if _focus_policy == 1 or not preserve:
		_primary().grab_focus()
	_focus_policy = 0


func _on_servo_pressed() -> void:
	if not visible or not _locked_id.is_empty() or _servo_action.disabled:return
	_locked_id="servo_remove" if _servo_installed else "servo_install" if _servo_owned else "servo_craft"
	_servo_action.disabled=true;action_requested.emit(_locked_id)


func _on_action_pressed(id: String) -> void:
	# Kurze Sperre bis Owner update_state aufruft — verhindert Doppelsignale.
	if not visible or not _locked_id.is_empty():return
	if id=="servo_trial":
		if _trial_action.disabled:return
		_locked_id=id;_trial_action.disabled=true;action_requested.emit(id);return
	if id not in [ID_STARTER,ID_VIBRO]:return
	if (id==ID_STARTER and _starter_action.disabled) or (id==ID_VIBRO and _vibro_action.disabled):return
	_locked_id = id
	if id == ID_VIBRO:
		_vibro_action.disabled = true
	else:
		_starter_action.disabled = true
	action_requested.emit(id)


func _on_close_pressed() -> void:
	# UI erfasst selbst kein Esc/B; der Zurück-Knopf emittiert nur.
	close_requested.emit()


func _build_once() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = COLOR_BACKDROP
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = Color(COLOR_COPPER.r, COLOR_COPPER.g, COLOR_COPPER.b, 0.7)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	_panel.add_child(_mk_label("TitleLabel", "WERKBANK", 20, COLOR_COPPER, Vector2(16, 12)))
	_balance_label = _mk_label("BalanceLabel", "Splitter: 0", 14, COLOR_TEXT, Vector2(16, 42))
	_panel.add_child(_balance_label)

	_starter_info = _mk_label("StarterInfo", ITEMS.label(ID_STARTER)+"\n"+ITEMS.summary(ID_STARTER), 14, COLOR_TEXT, Vector2(16, 65))
	_panel.add_child(_starter_info)
	_starter_action = _mk_button("StarterAction", "Ausrüsten", Vector2(16, 68))
	_starter_action.pressed.connect(_on_action_pressed.bind(ID_STARTER))
	_panel.add_child(_starter_action)

	_vibro_info = _mk_label("VibroInfo", ITEMS.label(ID_VIBRO)+"\n"+ITEMS.summary(ID_VIBRO), 14, COLOR_TEXT, Vector2(16, 108))
	_panel.add_child(_vibro_info)
	_vibro_action = _mk_button("VibroAction", "Kaufen · %d Splitter"%VIBRO_COST, Vector2(16, 114))
	_vibro_action.pressed.connect(_on_action_pressed.bind(ID_VIBRO))
	_panel.add_child(_vibro_action)
	_shortage_label = _mk_label("ShortageLabel", "", 11, COLOR_COPPER, Vector2(16, 148))
	_shortage_label.visible = false
	_panel.add_child(_shortage_label)

	_feedback_label = _mk_label("FeedbackLabel", "", 12, COLOR_COPPER, Vector2(16, 194))
	_feedback_label.visible = false
	_panel.add_child(_feedback_label)

	_servo_info=_mk_label("ServoInfo",PREFIX.summary(),13,COLOR_TEXT,Vector2(16,152))
	_panel.add_child(_servo_info)
	_servo_action=_mk_button("ServoAction","Herstellen",Vector2(16,154))
	_servo_action.pressed.connect(_on_servo_pressed);_panel.add_child(_servo_action)
	_trial_info=_mk_label("ServoTrialInfo","Freiwillig: 12 Splitter + mindestens 1 Servo",12,COLOR_MUTED,Vector2(16,196))
	_panel.add_child(_trial_info)
	_trial_action=_mk_button("ServoTrialAction","Servoteile bergen · 5 Roboter",Vector2(16,212))
	_trial_action.pressed.connect(_on_action_pressed.bind("servo_trial"))
	_panel.add_child(_trial_action)

	_btn_close = _mk_button("CloseButton", "Zurück", Vector2(16, 200))
	_btn_close.pressed.connect(_on_close_pressed)
	_panel.add_child(_btn_close)

	_footer_label = _mk_label("FooterLabel", "Eingabe / A: wählen · Esc / B: zurück", 12, COLOR_MUTED, Vector2.ZERO)
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_footer_label)

	# Deterministische Auf-/Ab-Navigation: fester Ein-/Aus-Zyklus über die drei
	# Buttons; links/rechts blockiert. ui_accept bleibt eingebaut aktiv.
	var buttons := [_starter_action,_vibro_action,_servo_action,_trial_action,_btn_close]
	for i in buttons.size():
		var b: Button=buttons[i]
		b.focus_neighbor_top=b.get_path_to(buttons[posmod(i-1,buttons.size())])
		b.focus_neighbor_bottom=b.get_path_to(buttons[(i+1)%buttons.size()])
		b.focus_neighbor_left=b.get_path_to(b)
		b.focus_neighbor_right=b.get_path_to(b)


func _mk_label(node_name: String, txt: String, font_size: int, color: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = txt
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _mk_button(node_name: String, txt: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = txt
	b.position = pos
	b.mouse_filter = Control.MOUSE_FILTER_STOP  # Maus UND Tastatur/Gamepad (ui_accept)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", COLOR_TEXT)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.52, 0.51))
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BTN
	normal.set_corner_radius_all(4)
	normal.set_border_width_all(1)
	normal.border_color = Color(COLOR_COPPER.r, COLOR_COPPER.g, COLOR_COPPER.b, 0.8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_BTN_HOVER
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = COLOR_BTN_DISABLED
	disabled.border_color = Color(0.3, 0.32, 0.32, 0.6)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", hover)
	return b


func _layout() -> void:
	if _panel == null:
		return
	var vw: float = _view_size.x
	var vh: float = _view_size.y
	# Top-left-Ananker (kein Full-rect-Preset): Root kann unter CanvasLayer 0x0 sein.
	position = Vector2.ZERO
	offset_left = 0.0
	offset_top = 0.0
	offset_right = vw
	offset_bottom = vh
	_backdrop.size = _view_size
	var w: float = minf(480.0, vw - 24.0)
	var h: float = minf(336.0, vh - 24.0)
	_panel.size = Vector2(w, h)
	_panel.position = Vector2((vw - w) * 0.5, (vh - h) * 0.5)
	_servo_action.size=Vector2(150,30);_servo_action.position=Vector2(w-166,154)
	_servo_info.size=Vector2(maxf(140,w-190),40)
	_servo_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_starter_action.size = Vector2(150.0, 30.0)
	_vibro_action.size = Vector2(150.0, 30.0)
	_btn_close.size = Vector2(150.0, 30.0)
	_trial_info.size=Vector2(w-32.0,20.0)
	_trial_action.size=Vector2(w-32.0,30.0)
	_trial_action.position=Vector2(16,h-112.0)
	_starter_action.position = Vector2(w - 166.0, 64.0)
	_vibro_action.position = Vector2(w - 166.0, 110.0)
	_btn_close.position = Vector2((w - 150.0) * 0.5, h - 76.0)
	var info_w: float = maxf(140.0, w - 190.0)
	_starter_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_vibro_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_starter_info.size = Vector2(info_w, 40.0)
	_vibro_info.size = Vector2(info_w, 40.0)
	_balance_label.size = Vector2(w - 32.0, 18.0)
	_feedback_label.size = Vector2(w - 32.0, 28.0)
	_shortage_label.size = Vector2(w - 32.0, 14.0)
	_footer_label.position = Vector2(16.0, h - 38.0)
	_footer_label.size = Vector2(w - 32.0, 18.0)


func move_selection(direction:int) -> void:
	if not visible:return
	var enabled:Array[Button]=[]
	for button in [_starter_action,_vibro_action,_servo_action,_trial_action,_btn_close]:
		if button.visible and not button.disabled:enabled.append(button)
	if enabled.is_empty():return
	var current:=enabled.find(get_viewport().gui_get_focus_owner())
	enabled[posmod(current+direction,enabled.size())].grab_focus()
