extends Control
# H68 — Labor-Aufseher boss status HUD (isolated deliverable, no class_name).
# Owner-driven only: call update_state() after ready from the real boss
# encounter. No combat, damage/healing, input, pause or save logic.
# Built-in font/styleboxes only; no textures, lights, assets or services.

const TITLE_TEXT: String = "LABOR-AUFSEHER"
const MAX_BLOCK_WIDTH: float = 340.0
const WIDTH_FACTOR: float = 0.6
const TOP_ABOVE_BOTTOM: float = 105.0     # block top edge: 105 px above bottom
const BOTTOM_ABOVE_BOTTOM: float = 64.0   # block bottom edge: 64 px above bottom
const TITLE_FONT_SIZE: int = 18
const PHASE_FONT_SIZE: int = 16
const BAR_HEIGHT: float = 8.0
const SIDE_PAD: float = 8.0

const COLOR_BACKING: Color = Color(0.06, 0.05, 0.045, 0.72)
const COLOR_FILL: Color = Color(0.78, 0.52, 0.30)          # muted warm orange
const COLOR_BAR_BG: Color = Color(0.12, 0.11, 0.10, 0.90)
const COLOR_TEXT: Color = Color(0.92, 0.88, 0.82)
const COLOR_PHASE: Color = Color(0.80, 0.74, 0.66)

var _active: bool = false
var _hp: int = 0
var _max_hp: int = 1
var _phase: int = 1
var _braced := false

var _panel: Panel
var _title: Label
var _phase_label: Label
var _bar: ProgressBar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	get_viewport().size_changed.connect(_sync_viewport_size)
	_sync_viewport_size()
	_build_once()
	_refresh()
	_apply_layout()
	visible = false


func update_state(active: bool, hp: int, max_hp: int, phase: int, braced: bool=false) -> void:
	_braced=braced
	_active = active
	_max_hp = maxi(max_hp, 1)
	_hp = clampi(hp, 0, _max_hp)
	_phase = phase if (phase == 1 or phase == 2) else 1
	_refresh()
	_apply_layout()
	visible = _active


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_layout()


func _build_once() -> void:
	_panel = Panel.new()
	_panel.name = "OverseerBlock"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing := StyleBoxFlat.new()
	backing.bg_color = COLOR_BACKING
	backing.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override("panel", backing)
	add_child(_panel)

	_title = Label.new()
	_title.name = "TitleLabel"
	_title.text = TITLE_TEXT
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title.add_theme_color_override("font_color", COLOR_TEXT)
	_panel.add_child(_title)

	_phase_label = Label.new()
	_phase_label.name = "PhaseLabel"
	_phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_label.add_theme_font_size_override("font_size", PHASE_FONT_SIZE)
	_phase_label.add_theme_color_override("font_color", COLOR_PHASE)
	_panel.add_child(_phase_label)

	_bar = ProgressBar.new()
	_bar.name = "HealthBar"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_FILL
	fill.set_corner_radius_all(2)
	var bg := StyleBoxFlat.new()
	bg.bg_color = COLOR_BAR_BG
	bg.set_corner_radius_all(2)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", bg)
	_panel.add_child(_bar)


func _refresh() -> void:
	if _panel == null:
		return
	_phase_label.text = "STANDHAFT" if _braced else "Phase %d" % _phase
	_bar.max_value = float(_max_hp)
	_bar.value = float(_hp)


func _apply_layout() -> void:
	if _panel == null:
		return
	# Compact bottom-center block; keeps the objective band (bottom 46 px /
	# footer 30 px) and the interact prompt (starts 140 px above bottom) free.
	var block_w: float = minf(MAX_BLOCK_WIDTH, size.x * WIDTH_FACTOR)
	var block_h: float = TOP_ABOVE_BOTTOM - BOTTOM_ABOVE_BOTTOM
	var block_x: float = (size.x - block_w) * 0.5
	var block_y: float = size.y - TOP_ABOVE_BOTTOM
	_panel.position = Vector2(block_x, block_y)
	_panel.size = Vector2(block_w, block_h)
	_title.position = Vector2(SIDE_PAD, 2.0)
	_bar.position = Vector2(SIDE_PAD, block_h - BAR_HEIGHT - 4.0)
	_bar.size = Vector2(block_w - SIDE_PAD * 2.0, BAR_HEIGHT)
	var phase_w: float = _phase_label.get_minimum_size().x
	_phase_label.position = Vector2(block_w - SIDE_PAD - phase_w, 4.0)


func _sync_viewport_size() -> void:
	# CanvasLayer is not a Control; explicitly follow its viewport rectangle.
	size = get_viewport().get_visible_rect().size
